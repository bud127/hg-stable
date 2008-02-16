# hgweb/request.py - An http request from either CGI or the standalone server.
#
# Copyright 21 May 2005 - (c) 2005 Jake Edge <jake@edge2.net>
# Copyright 2005, 2006 Matt Mackall <mpm@selenic.com>
#
# This software may be used and distributed according to the terms
# of the GNU General Public License, incorporated herein by reference.

import socket, cgi, errno
from mercurial.i18n import gettext as _
from common import ErrorResponse, statusmessage

class wsgirequest(object):
    def __init__(self, wsgienv, start_response):
        version = wsgienv['wsgi.version']
        if (version < (1, 0)) or (version >= (2, 0)):
            raise RuntimeError("Unknown and unsupported WSGI version %d.%d"
                               % version)
        self.inp = wsgienv['wsgi.input']
        self.err = wsgienv['wsgi.errors']
        self.threaded = wsgienv['wsgi.multithread']
        self.multiprocess = wsgienv['wsgi.multiprocess']
        self.run_once = wsgienv['wsgi.run_once']
        self.env = wsgienv
        self.form = cgi.parse(self.inp, self.env, keep_blank_values=1)
        self._start_response = start_response
        self.server_write = None
        self.headers = []

    def __iter__(self):
        return iter([])

    def read(self, count=-1):
        return self.inp.read(count)

    def respond(self, status, type=None, filename=None, length=0):
        if self._start_response is not None:

            self.httphdr(type, filename, length)
            if not self.headers:
                raise RuntimeError("request.write called before headers sent")

            for k, v in self.headers:
                if not isinstance(v, str):
                    raise TypeError('header value must be string: %r' % v)

            if isinstance(status, ErrorResponse):
                status = statusmessage(status.code)
            elif status == 200:
                status = '200 Script output follows'
            elif isinstance(status, int):
                status = statusmessage(status)

            self.server_write = self._start_response(status, self.headers)
            self._start_response = None
            self.headers = []

    def write(self, thing):
        if hasattr(thing, "__iter__"):
            for part in thing:
                self.write(part)
        else:
            thing = str(thing)
            try:
                self.server_write(thing)
            except socket.error, inst:
                if inst[0] != errno.ECONNRESET:
                    raise

    def writelines(self, lines):
        for line in lines:
            self.write(line)

    def flush(self):
        return None

    def close(self):
        return None

    def header(self, headers=[('Content-Type','text/html')]):
        self.headers.extend(headers)

    def httphdr(self, type=None, filename=None, length=0, headers={}):
        headers = headers.items()
        if type is not None:
            headers.append(('Content-Type', type))
        if filename:
            headers.append(('Content-Disposition',
                            'inline; filename=%s' % filename.split('/')[-1]))
        if length:
            headers.append(('Content-Length', str(length)))
        self.header(headers)

def wsgiapplication(app_maker):
    '''For compatibility with old CGI scripts. A plain hgweb() or hgwebdir()
    can and should now be used as a WSGI application.'''
    application = app_maker()
    def run_wsgi(env, respond):
        return application(env, respond)
    return run_wsgi
