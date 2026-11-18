#!/usr/bin/env python3
"""Fake Asterisk, for playing ZK$PHONE over FastAGI from a terminal.

Connects to the ZKPHONE service and plays the Asterisk side: prints what
would be spoken and reads keypad keys (0-9, * and #) from the keyboard.
q hangs up.  When the game listens (GOSUB ifc-hear), type what the
caller says and press Return; it is cleaned up as ifc-hear does, except
for the number words.
"""
import argparse, os, re, select, socket, subprocess, sys, termios, textwrap, tty

KEYS = '0123456789*#'


class Keypad:
    def __init__(self):
        self.fd = sys.stdin.fileno()
        self.saved = termios.tcgetattr(self.fd)

    def __enter__(self):
        tty.setcbreak(self.fd)
        return self

    def __exit__(self, *exc):
        termios.tcsetattr(self.fd, termios.TCSADRAIN, self.saved)

    def key(self, timeout):
        """A keypad key, 'q', or '' on timeout; None waits for ever."""
        while True:
            ready, _, _ = select.select([self.fd], [], [], timeout)
            if not ready:
                return ''
            c = os.read(self.fd, 1).decode('latin-1').lower()
            if c in KEYS or c == 'q':
                return c

    def line(self):
        """A line typed for ifc-hear, echoed; Return ends it."""
        text = ''
        while True:
            c = os.read(self.fd, 1).decode('latin-1')
            if c in '\r\n':
                print()
                return text
            text += c
            print(c, end='', flush=True)


class Call:
    def __init__(self, sock, keypad, args):
        self.sock, self.keypad, self.args = sock, keypad, args
        self.rfile = sock.makefile('rb')
        self.variables = {}
        self.texts = {}             # sound name -> text, from ifc-say
        self.dead = self.done = False

    def log(self, direction, line):
        if self.args.log:
            print(f'{direction} {line}', file=sys.stderr)

    def send(self, line):
        self.log('<<', line)
        self.sock.sendall((line + '\n').encode('latin-1'))

    def run(self):
        for header in ('agi_network: yes',
                       f'agi_network_script: {self.args.script}',
                       f'agi_request: agi://{self.args.host}/{self.args.script}',
                       'agi_channel: Local/fake-agi',
                       'agi_language: en',
                       'agi_type: Local',
                       'agi_uniqueid: fake.1',
                       f'agi_callerid: {self.args.callerid}',
                       'agi_calleridname: unknown',
                       'agi_context: ifc',
                       'agi_extension: s',
                       'agi_priority: 1',
                       ''):
            self.send(header)
        while not self.done:
            line = self.rfile.readline()
            if not line:
                print('[connection closed]')
                break
            line = line.decode('latin-1').rstrip('\r\n')
            self.log('>>', line)
            self.send(self.handle(line))

    def hang_up(self):
        print('[you hung up]')
        self.send('HANGUP')
        self.dead = True

    def play(self, text, escape):
        """Play a text or a fixed prompt; returns the key that stopped it."""
        if self.args.say:
            speech = subprocess.Popen(['say', text])
            try:
                while speech.poll() is None:
                    k = self.keypad.key(0.05)
                    if k == 'q' or (k and k in escape):
                        return k
            finally:
                speech.terminate()
            return ''
        k = self.keypad.key(0)          # typed ahead
        return k if (k == 'q' or k in escape) else ''

    def handle(self, line):
        if self.dead:
            return '511 Command Not Permitted on a dead channel'

        m = re.match(r'SET VARIABLE (\S+) "(.*)"$', line)
        if m:
            self.variables[m[1]] = re.sub(r'\\(.)', r'\1', m[2])
            return '200 result=1'

        m = re.match(r'GOSUB (\S+) (\S+) (\S+)(?: (\S+))?$', line)
        if m:
            if m[1] == 'ifc-say' and m[4]:
                name = m[4].split(',')[-1]
                self.texts[name] = self.variables.get('IFC_TEXT', '')
                self.variables['SYSTEMSTATUS'] = 'SUCCESS'
            if m[1] == 'ifc-hear':
                print('[beep: say it, then Return]')
                words = re.sub(r'[^A-Z0-9]+', ' ', self.keypad.line().upper())
                self.variables['IFC_HEARD'] = words.strip()
            self.send('100 result=0 Trying...')     # as real Asterisk does
            return '200 result=0 Gosub complete'

        m = re.match(r'GET VARIABLE (\S+)$', line)
        if m:
            if m[1] in self.variables:
                return f'200 result=1 ({self.variables[m[1]]})'
            return '200 result=0'

        m = re.match(r'STREAM FILE (\S+) "([^"]*)"', line)
        if m:
            name = m[1].split('/')[-1]
            text = self.texts.get(name)
            if text is None:
                print(f'[{name}]')
                text = name.replace('_', ' ')
            else:
                print(textwrap.fill(text, 72))
            k = self.play(text, m[2])
            if k == 'q':
                self.hang_up()
                return '200 result=-1 endpos=0'
            return f'200 result={ord(k) if k else 0} endpos=0'

        m = re.match(r'WAIT FOR DIGIT (-?\d+)$', line)
        if m:
            ms = int(m[1])
            k = self.keypad.key(None if ms < 0 else ms / 1000)
            if k == 'q':
                self.hang_up()
                return '200 result=-1'
            return f'200 result={ord(k) if k else 0}'

        if line == 'HANGUP':
            print('[the game hung up]')
            self.done = True
            return '200 result=1'

        return '510 Invalid or unknown command'


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument('host')
    p.add_argument('--port', type=int, default=4573)
    p.add_argument('--script', default='zk', help='agi_network_script')
    p.add_argument('--callerid', default='0000000000')
    p.add_argument('--say', action='store_true', help='speak with say(1)')
    p.add_argument('--log', action='store_true', help='show the protocol')
    args = p.parse_args()

    print('Keys: 0-9, * and #.  q hangs up.')
    with socket.create_connection((args.host, args.port)) as sock, \
         Keypad() as keypad:
        Call(sock, keypad, args).run()


if __name__ == '__main__':
    main()
