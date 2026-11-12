// markdown viewer for sushi (nautilus previewer)

const {Gio, GLib, GObject} = imports.gi;

var WebKit2;
try {
    imports.gi.versions.WebKit2 = '4.1';
    WebKit2 = imports.gi.WebKit2;
} catch (e) {
}

const Renderer = imports.ui.renderer;

const CMARK = '@cmark@';

const STYLE = `
:root { color-scheme: dark light; --bg: #1e1e1e; --fg: #d4d4d4; --muted: #8b8b8b;
        --border: #3a3a3a; --code-bg: #2a2a2a; --link: #6cb6ff; }
@media (prefers-color-scheme: light) {
  :root { --bg: #ffffff; --fg: #1f2328; --muted: #59636e; --border: #d1d9e0;
          --code-bg: #f6f8fa; --link: #0969da; }
}
html { background: var(--bg); }
body { color: var(--fg); font: 15px/1.6 sans-serif; max-width: 860px;
       margin: 0 auto; padding: 24px 32px 48px; word-wrap: break-word; }
h1, h2 { border-bottom: 1px solid var(--border); padding-bottom: .3em; }
h1, h2, h3, h4, h5, h6 { margin: 1.4em 0 .6em; line-height: 1.25; }
a { color: var(--link); text-decoration: none; }
img { max-width: 100%; }
code, pre { font-family: monospace; font-size: 90%; background: var(--code-bg); border-radius: 6px; }
code { padding: .15em .35em; }
pre { padding: 12px 16px; overflow: auto; }
pre code { padding: 0; background: none; font-size: 100%; }
blockquote { margin: 0; padding: 0 1em; color: var(--muted); border-left: 4px solid var(--border); }
table { border-collapse: collapse; display: block; overflow: auto; }
th, td { border: 1px solid var(--border); padding: 6px 13px; }
hr { border: 0; border-top: 1px solid var(--border); }
li > input[type=checkbox] { margin-right: .4em; }
`;

function _escape(text) {
    return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function _render(file) {
    let path = file.get_path();
    try {
        let proc = Gio.Subprocess.new(
            [CMARK, '--unsafe',
             '-e', 'table', '-e', 'strikethrough', '-e', 'autolink', '-e', 'tasklist',
             path],
            Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE);
        let [, stdout] = proc.communicate_utf8(null, null);
        if (proc.get_successful())
            return stdout;
    } catch (e) {
        logError(e, 'markdown: cmark-gfm failed');
    }
    // fallback: show the raw text
    let [, bytes] = GLib.file_get_contents(path);
    return `<pre>${_escape(new TextDecoder().decode(bytes))}</pre>`;
}

var Klass = WebKit2 ? GObject.registerClass({
    Implements: [Renderer.Renderer],
    Properties: {
        fullscreen: GObject.ParamSpec.boolean('fullscreen', '', '',
                                              GObject.ParamFlags.READABLE, false),
        ready: GObject.ParamSpec.boolean('ready', '', '',
                                         GObject.ParamFlags.READABLE, false),
    },
}, class MarkdownRenderer extends WebKit2.WebView {
    get ready() {
        return !!this._ready;
    }

    get fullscreen() {
        return !!this._fullscreen;
    }

    _init(file) {
        super._init();

        this.connect('context-menu', () => true);
        this.connect('load-failed', (view, loadEvent, uri, error) => {
            this.emit('error', error);
        });

        let html = `<!doctype html><html><head><meta charset="utf-8">` +
                   `<style>${STYLE}</style></head><body>${_render(file)}</body></html>`;
        // base uri = the file itself, so relative images resolve
        this.load_html(html, file.get_uri());
        this.isReady();
    }

    get moveOnClick() {
        return false;
    }
}) : undefined;

var mimeTypes = WebKit2 ? ['text/markdown', 'text/x-markdown'] : [];
