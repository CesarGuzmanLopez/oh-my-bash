# 🌀 oh-my-bash-fork

Fork personal de [Oh My Bash](https://github.com/ohmybash/oh-my-bash) con tema **kitsune**, aliases personalizados, scripts útiles (TARDIS, hoy, note) y una selección de los plugins más usados listos desde el primer momento.

## ⚡ Instalación

**Rápida (una línea, con verificación de dependencias):**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/CesarGuzmanLopez/oh-my-bash/master/tools/install-fork.sh)"
```

Opciones del instalador: `--dir DIR`, `--no-ble` (solo el fork), `--dry-run`, `--help`.

**Manual:** clona el repo y añade esto a tu `~/.bashrc`:

```bash
export OSH="$HOME/oh-my-bash-fork"
source "$OSH/oh-my-bash.sh"
```

### Dependencias

El instalador las comprueba todas y **no falla si falta alguna**: simplemente esa función no aparece (degradación elegante).

| Programa | ¿Obligatorio? | Habilita |
|---|---|---|
| `bash` ≥ 3.2 | ✅ | El fork (ble.sh 0.4 necesita ≥ 4.3) |
| `git` | ✅ (para instalar) | Clonar/actualizar el fork |
| `curl` | Opcional | Descargar ble.sh, `hoy` |
| `fzf` | Opcional | `Ctrl+F`, `Ctrl+T`, menús difusos |
| `atuin` | Opcional | Historia SQLite y `Ctrl+R` |
| `aichat` | Opcional | `ai`, `C-x i` |
| `jq` | Opcional | `hoy`, parseo JSON |
| `rg` | Opcional | Búsqueda de `Ctrl+F` |
| `bat` | Opcional | Previsualización y `cat` |
| `eza` | Opcional | `ls` con iconos y git |
| `zoxide` | Opcional | `z` (salto inteligente de directorios) |
| `make`, `gawk` | Opcional | Compilar ble.sh |
| `kitten` (kitty) | Opcional | Integración SSH de kitty |
| `python3` | Opcional | `tardis` |

```bash
# Arch
sudo pacman -S fzf atuin aichat jq ripgrep bat eza zoxide make gawk
# Debian/Ubuntu (atuin/aichat suelen ir por binario oficial)
sudo apt install fzf jq ripgrep bat eza zoxide make gawk
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
```

El fork es **auto-contenido**:
- ✅ **`$OSH` se detecta solo** — no necesitas exportarlo manualmente
- ✅ **Tema kitsune** activado por defecto: paleta dinámica, ajuste automático **claro/oscuro** (KDE, GNOME, kitty o `COLORFGBG`) y **respaldo ANSI** para SSH desde Windows/Mac
- ✅ **Plugins esenciales** pre-cargados: `git`, `colored-man-pages`, `sudo`, `bashmarks`, `battery`, `progress`, `cargo`, `npm`
- ✅ **Aliases útiles**: `ll`, `c` (clear), `src` (recargar .bashrc), `path`, `ssh` (sin el error `xterm-kitty`), etc.
- ✅ **Completions**: `git`, `ssh`, `composer`, `npm`, `docker`, `system`
- ✅ **Auto-update desactivado** por ser un fork

### Tokens personales (opcional)

Crea un archivo `.env` en la raíz del fork (está en `.gitignore`):

```bash
TOKEN_telegram=tu_token
TOKEN_USER_telegram=tu_user_id
TOKEN_MEMOS=tu_token_memos
```

### Tema kitsune — requisito opcional

El tema usa colores dinámicos desde la paleta de **kitty**.
Si no usas kitty, usa la detección de esquema (KDE/GNOME/`COLORFGBG`) con colores de respaldo.
Si tu shell no carga `~/.bashrc` (login shells), añade estas tres líneas en `~/.bash_profile`:
```bash
if [[ -f ~/.bashrc ]]; then
  source ~/.bashrc
fi
```

### Tema claro/oscuro (KDE, GNOME, kitty)

El tema **kitsune** tiene tres modos de color:

- **dark**: fondos sólidos oscuros (acentos al 30 %) y texto claro.
- **light**: fondos pastel y texto oscuro.
- **ansi**: sin bloques RGB; usa solo los colores ANSI del terminal. Se adapta a cualquier terminal (claro u oscuro) y es el modo de respaldo cuando no se puede detectar el esquema.

Orden de detección en `auto`:

1. **kitty** en vivo (`kitten @ get-colors background`)
2. sesión **remota sin kitty** (SSH desde Windows/macOS): → `ansi`
3. **KDE Plasma** solo si la sesión está activa (`KDE_FULL_SESSION`/`XDG_CURRENT_DESKTOP`/`plasma`/`kwin`, o `kreadconfig6`/`kreadconfig5`)
4. **GNOME** (`gsettings color-scheme` / `gtk-theme`)
5. `$COLORFGBG`
6. respaldo → `ansi`

Así, con KDE/kitty el tema es **dinámico**; conectándote por SSH desde Windows o Mac (sin KDE/kitty) queda **funcional** usando la familia de colores del terminal. El watcher solo se ejecuta cuando hay una fuente que puede cambiar (kitty/KDE/GNOME), así que en SSH no consume nada.

Variables:

```bash
OSH_THEME_SCHEME=auto          # auto (por defecto) | dark | light | ansi
OSH_THEME_SCHEME_INTERVAL=3    # segundos entre re-detecciones (solo si hay fuente dinámica; 0 desactiva)
```

El tema se **re-evalúa en cada prompt** (con ese intervalo). Al cambiar el tema del SO/kitty, el **siguiente prompt ya sale con los colores nuevos** (no hace falta reiniciar bash). Los prompts ya dibujados no cambian. Para aplicarlo al instante:

```bash
refreshcolor              # recarga kitty (si existe) + re-aplica el tema ahora
OSH_THEME_SCHEME=light _omb_theme_reload_colors
```

### SSH desde kitty — `'xterm-kitty': unknown terminal type`

`kitty` define `TERM=xterm-kitty`, que no existe en la mayoría de servidores. Además, `kitty +kitten ssh` copia la terminfo y exporta `TERMINFO=$HOME/.terminfo`, así que al hacer `sudo -i`/`su` cambia el HOME y root deja de encontrarla.

Este fork lo soluciona así:

| Comando | Qué hace |
|---|---|
| `ssh` | usa `TERM=xterm-256color` + `kitty +kitten ssh`. `xterm-256color` existe en todos los servidores y sobrevive a `su`/`sudo -i`. |
| `ssh-kitty` | integración completa de kitty (`TERM=xterm-kitty`). |
| `ssh-term-fix usuario@host` | instala `xterm-kitty` en `/usr/share/terminfo` del remoto (solución global para root/su/sudo). |
| `ssh-term-safe usuario@host` | fuerza `TERM=xterm-256color` en la sesión remota sin tocar el servidor. |
| `kitty-term-info` | comprueba si la terminfo local está disponible. |

Ejemplo de un host que da el error, arreglado de forma permanente:

```bash
ssh-term-fix root@ubuntu
```

## ✨ Extras del fork

### CLI moderna (con fallback)
- `ls`/`l`/`ll`/`la`/`lt`/`lr` usan **eza** (iconos + git) si está instalado; si no, `ls` normal.
- `cat`/`catn`/`catp` usan **bat**.
- Desactívalo con `OSH_MODERN_CLI=0`. Reemplazos de `grep`/`find` (semántica distinta): `OSH_MODERN_CLI_AGGRESSIVE=1`.

### zoxide
Se carga automáticamente si `zoxide` está instalado: `z dir`, `zi`. Desactívalo con `OSH_ENABLE_ZOXIDE=0`.

### Funciones y helpers
| Comando | Qué hace |
|---|---|
| `take DIR` / `mkcd DIR` | crea el directorio y entra |
| `extract FILE` | descomprime tar/zip/7z/rar/gz/xz/zst/rpm/deb |
| `gcof` | cambiar de rama git con fzf (preview del log) |
| `killf` | elegir y matar un proceso |
| `cdf` / `editf` | cd / abrir archivo con fzf |
| `note -l` | listar/buscar notas con fzf |
| `git-sync-a-pruebas` | sincroniza ramas de `origin` a `pruebas` |
| `updateAll` | actualiza y limpia el sistema (solo Arch) |
| `refreshcolor` | recarga kitty y re-aplica el tema |

### Rendimiento del prompt
- El git status se calcula en un directorio solo si es un repo, y opcionalmente en segundo plano: `OSH_PROMPT_ASYNC_GIT=1`.
- Perfilado de arranque por fases: `OSH_PROFILE=1 bash -lic true`.

### Calidad
- `shellcheck` + `shfmt` sobre `custom/` y scripts del fork.
- Tests con `bats`: `bats tests/`.
- `hoy` requiere `WEATHERAPI_KEY` en `.env`.

## 🐚 Shell interactivo: ble.sh + atuin + IA (Groq)

Instalador idempotente (no instala paquetes, solo configura):

```bash
tools/setup-shell-extras.sh --dry-run   # ver qué haría
tools/setup-shell-extras.sh             # aplicar
sudo pacman -S atuin aichat             # dependencias
```

### ble.sh (ghost text + resaltado de sintaxis)
- Instalación user-space (sin sudo): `make install PREFIX=~/.local` → `~/.local/share/blesh`.
- En `~/.bashrc`: `source .../ble.sh --attach=none` al inicio y `ble-attach` al final.
- `~/.blerc` (plantilla en `templates/blerc.example`):
  - `bleopt prompt_command_changes_layout=1` (el tema kitsune reescribe `PS1`).
  - fzf vía `ble-import integration/fzf-*` de blesh-contrib.
- Con ble.sh, los bindings del fork usan `ble-bind` (`Ctrl+F` buscar, `Ctrl+T` insertar).

### atuin (historia + `Ctrl+R` + sync)
- `sudo pacman -S atuin` y `eval "$(atuin init bash)"` al final de `~/.bashrc`.
- Usa ble.sh como backend de `preexec`; compruébalo con `atuin doctor` → `"preexec": "blesh-…"`.

### IA con Groq (`openai/gpt-oss-20b`)
`aichat` configurado con el cliente `groq` (OpenAI-compatible) y
`reasoning_format: hidden` para que **no** muestre el bloque `<think>`.

```bash
ai "lista los archivos más grandes"   # genera el comando (no lo ejecuta)
ai -x "cuenta los .sh del directorio" # genera y ejecuta (confirmación)
ai -e "df -h"                         # explica un comando
ai -m "¿qué hace trap en bash?"       # chat normal
ai <Tab>                              # completa las banderas (-x/-e/-m/…)
ai --help
```
- Tecla `C-x i` (ble.sh): toma lo escrito y lo reemplaza por el comando generado.
- Requiere `GROQ_API_KEY` en `.env`; modelo configurable con `OSH_AI_MODEL`.

## Using Oh My Bash

### Plugins

Oh My Bash comes with a shit load of plugins to take advantage of. You can take a look in the [plugins](https://github.com/ohmybash/oh-my-bash/tree/master/plugins) directory and/or the [wiki](https://github.com/ohmybash/oh-my-bash/wiki/Plugins) to see what's currently available.

#### Enabling Plugins

Once you spot a plugin (or several) that you'd like to use with Oh My Bash, you'll need to enable them in the `.bashrc` file. You'll find the bashrc file in your `$HOME` directory. Open it with your favorite text editor and you'll see a spot to list all the plugins you want to load.

For example, this line might begin to look like this:

```shell
plugins=(git bundler osx rake ruby)
```

##### With Conditionals

You may want to control when and/or how plugins should be enabled.

For example, if you want the `tmux-autoattach` plugin to only run on SSH sessions, you could employ a trivial conditional that checks for the `$SSH_TTY` variable. Just make sure to remove the plugin from the larger plugin list.

``` bash
[ "$SSH_TTY" ] && plugins+=(tmux-autoattach)
```

#### Using Plugins

Most plugins (should! we're working on this) include a __README__, which documents how to use them.

### Themes

We'll admit it. Early in the Oh My Bash world, we may have gotten a bit too theme happy. We have over one hundred themes now bundled. Most of them have [screenshots](https://github.com/ohmybash/oh-my-bash/wiki/Themes) on our wiki or alternatively [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh/wiki/themes) wiki.

#### Selecting a Theme

_The font theme is the default one. It's not the fanciest one. It's not the simplest one. It's just the right one for the original maintainer of Oh My Bash._

Once you find a theme that you want to use, you will need to edit the `~/.bashrc` file. You'll see an environment variable (all caps) in there that looks like:

```shell
OSH_THEME="font"
```

To use a different theme, simply change the value to match the name of your desired theme. For example:

```shell
OSH_THEME="agnoster" # (this is one of the fancy ones)
# you might need to install a special Powerline font on your console's host for this to work
# see https://github.com/ohmybash/oh-my-bash/wiki/Themes#agnoster
```

Open up a new terminal window and your prompt should look something like this:

![Font theme](themes/font/font-dark.png)

In case you did not find a suitable theme for your needs, please have a look
at the wiki for [more of them](https://github.com/ohmybash/oh-my-bash/wiki/Themes).

If you're feeling feisty, you can let the computer select one randomly for you each time you open a new terminal window.

```shell
OSH_THEME="random" # (...please let it be pie... please be some pie..)
```

If you want to randomly select a theme from a specified list, you can set the
list in the following array:

```shell
OMB_THEME_RANDOM_CANDIDATES=("font" "powerline-light" "minimal")
```

If there are themes you don't like, you can add them to an ignored list:

```shell
OMB_THEME_RANDOM_IGNORED=("powerbash10k" "wanelo")
```

The selected theme name can be checked by the following command:

```shell
$ echo "$OMB_THEME_RANDOM_SELECTED"
```

## Advanced Topics

If you're the type that likes to get their hands dirty, these sections might resonate.

### Advanced Installation

Some users may want to change the default path, or manually install Oh My Bash.

#### Custom Directory

The default location is `~/.oh-my-bash` (hidden in your home directory)

If you'd like to change the install directory with the `OSH` environment variable, either by running `export OSH=/your/path` before installing, or by setting it before the end of the install pipeline like this:

```shell
export OSH="$HOME/.dotfiles/oh-my-bash"; bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
```

#### Unattended install

If you're running the Oh My Bash install script as part of an automated install, you can pass the
flag `--unattended` to the `install.sh` script. This will have the effect of not trying to change
the default shell, and also won't run `bash` when the installation has finished.

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
```

#### System-wide installation

For example, Oh My Bash can be installed to `/usr/local/share/oh-my-bash` for the system-wide installation by specifying the option `--prefix=PREFIX`.

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --prefix=/usr/local
```

To enable Oh My Bash, the Bash startup file `.bashrc` needs to be manually set up by each user.
The template of `.bashrc` is available in `PREFIX/share/oh-my-bash/bashrc`.
The users can copy the template file to `~/.bashrc` and edit it.

```bash
cp /usr/local/share/oh-my-bash/bashrc ~/.bashrc
```

#### Manual Installation

##### 1. Clone the repository:

```shell
git clone https://github.com/ohmybash/oh-my-bash.git ~/.oh-my-bash
```

##### 2. *Optionally*, backup your existing `~/.bashrc` file:

```shell
cp ~/.bashrc ~/.bashrc.orig
```

##### 3. Create a new sh configuration file

You can create a new sh config file by copying the template that we have included for you.

```shell
cp ~/.oh-my-bash/templates/bashrc.osh-template ~/.bashrc
```

##### 4. Reload your .bashrc

```shell
source ~/.bashrc
```

##### 5. Initialize your new bash configuration

Once you open up a new terminal window, it should load sh with Oh My Bash's configuration.

### Installation Problems

If you have any hiccups installing, here are a few common fixes.

* You _might_ need to modify your `PATH` in `~/.bashrc` if you're not able to find some commands after switching to `oh-my-bash`.
* If you installed manually or changed the install location, check the `OSH` environment variable in `~/.bashrc`.

### Customization of  Plugins and Themes

If you want to override any of the default behaviors, just add a new file (ending in `.sh`) in the `custom/` directory.

If you have many functions that go well together, you can put them as a
`XYZ.plugin.sh` file in the `custom/plugins/XYZ` directory and then enable this
plugin by adding the name to the `plugins` array in `~/.bashrc`.

If you would like to modify an existing module
(theme/plugin/aliases/completion) bundled with Oh My Bash, first copy the
original module to `custom/` directory and modify it.  It will be loaded
instead of the original one when it is enabled through
`OSH_THEME`/`plugins`/`aliases`/`completions` in `~/.bashrc`.

```bash
$ mkdir -p "$OSH_CUSTOM/themes"
$ cp -r {"$OSH","$OSH_CUSTOM"}/themes/agnoster
$ EDIT "$OSH_CUSTOM/themes/agnoster/agnoster.theme.sh"
```

If you would like to track the upstream changes for your customized version of
modules, you can optionally directly edit the original files and commit them.
In this case, you need to handle possible conflicts with the upstream
(`github.com/ohmybash/oh-my-bash`) in upgrading.

If you want to replace an existing module (theme/plugin/aliases/complet)
bundled with Oh My Bash, create a module of the same name in the `custom/`
directory so that it will be loaded instead of the original one.

### Configuration

#### Enable/disable python venv

The python virtualenv/condaenv information in the prompt may be enabled by the following line in `~/.bashrc`.

```bash
OMB_PROMPT_SHOW_PYTHON_VENV=true
```

Some themes turn on it by default.  If you would like to turn it off, you may disable it by the following line in `~/.bashrc`:

```bash
OMB_PROMPT_SHOW_PYTHON_VENV=false
```

#### Enable/disable Spack environment information

To enable the Spack environment information in the prompt, please set the
following shell variable in `~/.bashrc`:

```bash
OMB_PROMPT_SHOW_SPACK_ENV=true
```

If the theme supports it, the information of the currently active Spack
environment will be shown.  If the theme you use does not support the Spack
environment information, a pull request to add it is welcome.  See the `font`
theme as an example implementation of including the Spack environment.

#### Disable internal uses of `sudo`

Some plugins of oh-my-bash internally use `sudo` when it is necessary.  However, this might clutter with the `sudo` log.  To disable the use of `sudo` by oh-my-bash, `OMB_USE_SUDO` can be set to `false` in `~/.bashrc`.

```bash
OMB_USE_SUDO=false
```

Each plugin might provides finer configuration variables to control the use of `sudo` by each plugin.

## Getting Updates

By default, you will be prompted to check for upgrades every few weeks. If you would like `oh-my-bash` to automatically upgrade itself without prompting you, set the following in your `~/.bashrc`:

```shell
DISABLE_UPDATE_PROMPT=true
```

To disable automatic upgrades, set the following in your `~/.bashrc`:

```shell
DISABLE_AUTO_UPDATE=true
```

### Manual Updates

If you'd like to upgrade at any point in time (maybe someone just released a new plugin and you don't want to wait a week?) you just need to run:

```shell
upgrade_oh_my_bash
```

Magic!

## Uninstalling Oh My Bash

Oh My Bash isn't for everyone. We'll miss you, but we want to make this an easy breakup.

If you want to uninstall `oh-my-bash`, just run `uninstall_oh_my_bash` from the command-line. It will remove itself and revert your previous `bash` configuration.

## Contributing

Check out [`CONTRIBUTING.md`](CONTRIBUTING.md) and also [Code of
Conduct](CODE_OF_CONDUCT.md).

This project is initially ported from Oh My Zsh and Bash-it by `@nntoan` and
has been developed in a community-driven way.  Most of the contributors are far
from being [Bash](https://www.gnu.org/software/bash/) experts, and there are
many ways to improve the codebase.  We are looking for more people with
expertise in Bash scripting.  If you have ideas on how to make the
configuration easier to maintain (and faster), don't hesitate to fork and send
pull requests!

We also need people to test out pull-requests.  Take a look through [the open
issues](https://github.com/ohmybash/oh-my-bash/issues) and help where you can.

## Contributors

Oh My Bash has a vibrant community of happy users and delightful contributors. Without all the time and help from our contributors, it wouldn't be so awesome.

Thank you so much!

## License

See [`LICENSE.md`](License.md).
Oh My Bash is derived from [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh).
Oh My Bash is released under the [MIT license](LICENSE.md).
