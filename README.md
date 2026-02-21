# FlipClock

Widget desktop de flip clock minimalista, construido com Go e Fyne v2.

```
┌──────────┐   ┌──────────┐
│    14    │   │    35    │
└──────────┘   └──────────┘
                        07
```

## Funcionalidades

- Cards de hora e minuto com animacao flip (300ms, ease-in-out, duas fases)
- Layout responsivo que se adapta ao tamanho da janela
- Modo fullscreen (teclas `F` / `F11`)
- System tray com menu (Mostrar / Tela Cheia / Fechar)
- Fechar a janela minimiza para o tray (app continua rodando)
- Fonte Bebas Neue embutida no binario (zero dependencia de arquivos externos)
- Tema dark mode com paleta minimalista
- Formato 24 horas

## Stack

| Componente | Tecnologia |
|------------|-----------|
| Linguagem | [Go](https://go.dev/) 1.22+ |
| GUI | [Fyne](https://fyne.io/) v2.5.1 |
| Fonte | [Bebas Neue](https://fonts.google.com/specimen/Bebas+Neue) (OFL) |
| System Tray | [fyne.io/systray](https://github.com/nicoria/systray) |
| Rendering | OpenGL (via go-gl) |

## Pre-requisitos

- **Go 1.22+** ([download](https://go.dev/dl/))
- **Compilador C/C++** e bibliotecas OpenGL (necessarios pelo Fyne):

**Linux (Debian/Ubuntu):**

```bash
sudo apt install gcc libgl1-mesa-dev xorg-dev
```

**macOS:**

```bash
xcode-select --install
```

**Windows:**

- [TDM-GCC](https://jmeubank.github.io/tdm-gcc/) ou MSYS2

## Instalacao e execucao

```bash
# Clonar o repositorio
git clone https://github.com/nandomoreirame/flipclock-app.git
cd flipclock-app

# Baixar dependencias
go mod tidy

# Rodar direto
go run .

# Compilar binario
go build -o flipclock .

# Compilar binario otimizado (menor, sem simbolos de debug)
go build -ldflags "-s -w" -o flipclock .

# Linux/macOS: rodar em background
./flipclock &

# Windows (sem janela de console)
go build -ldflags "-s -w -H windowsgui" -o flipclock.exe .
```

## Atalhos de teclado

| Tecla | Acao |
|-------|------|
| `Esc` | Sai do fullscreen, ou minimiza para tray |
| `Q` | Minimiza para tray |
| `F` ou `F11` | Alterna fullscreen |

## Menu do System Tray

| Item | Acao |
|------|------|
| Mostrar | Exibe e foca a janela |
| Tela Cheia | Alterna fullscreen |
| Fechar | Encerra o aplicativo |

### Tray no Linux (GNOME)

O GNOME puro nao exibe tray icons nativamente. Instale a extensao AppIndicator:

```bash
sudo apt install gnome-shell-extension-appindicator
# Reinicie a sessao ou o GNOME Shell
```

KDE, XFCE, macOS e Windows funcionam out-of-the-box.

## Estrutura do projeto

```
flipclock-app/
├── main.go                      # Aplicacao (widgets, layout, tray, loop)
├── font.go                      # Fonte embutida via go:embed
├── bundled.go                   # Icone embutido via fyne bundle
├── fonts/
│   └── BebasNeue-Regular.ttf    # Fonte display (61KB, OFL license)
├── images/
│   ├── flipclock.png            # Icone do app (256x256)
│   ├── flipclock@2x.png         # Icone retina (512x512)
│   └── flipclock.svg            # Icone vetorial
├── install.sh                   # Installer automatico (Linux/macOS/Windows)
├── flipclock.desktop            # Desktop entry para Linux
├── FyneApp.toml                 # Metadados do app para fyne package
├── go.mod                       # Definicao do modulo Go
├── go.sum                       # Checksums das dependencias
├── CLAUDE.md                    # Instrucoes para o Claude Code
└── README.md                    # Este arquivo
```

### Secoes do main.go

| Secao | Linhas | Descricao |
|-------|--------|-----------|
| Colors | 16-26 | Paleta dark mode (`#000`, `#1A1A1A`, `#FFF`, `#555`) |
| flipTheme | 28-57 | Tema customizado do Fyne (cores + fonte BebasNeue) |
| FlipCard | 59-200 | Widget customizado com renderer e animacao flip |
| clockLayout | 202-265 | Layout responsivo com proporcao 5:6 dos cards |
| Clock | 267-290 | Estado do relogio + metodo `Update()` + helper `pad2` |
| main() | 292-402 | Setup do app, tray, atalhos, ticker loop de 1 segundo |

## Animacao flip

A animacao usa `fyne.NewAnimation()` com duracao de 300ms e curva ease-in-out, dividida em duas fases:

1. **Fase 1 (0-50%):** A aba superior encolhe do topo em direcao a dobradura central, revelando o novo digito por cima
2. **Fase 2 (50-100%):** A aba inferior encolhe de baixo em direcao a dobradura, revelando o novo digito por baixo

As abas usam a mesma cor do card (`#1A1A1A`), simulando o efeito mecanico de um flip clock real.

## Instalacao no sistema

O jeito mais facil de instalar e usar o script automatico:

```bash
./install.sh
```

O script detecta o OS (Linux, macOS, Windows), instala dependencias necessarias, compila o binario otimizado e registra o app no launcher do sistema.

Para desinstalar:

```bash
./install.sh --uninstall
```

### O que o install.sh faz por OS

**Linux (Debian/Ubuntu/Fedora/Arch):**

- Instala gcc e bibliotecas OpenGL (pede confirmacao antes de usar sudo)
- Compila o binario otimizado
- Instala em `~/.local/bin/flipclock`
- Registra icone e .desktop entry no launcher

**macOS:**

- Verifica Xcode CLI tools
- Compila e cria um .app bundle com Info.plist e icone .icns
- Instala em `~/Applications/FlipClock.app`

**Windows (MSYS2/Git Bash):**

- Verifica gcc (TDM-GCC ou MSYS2)
- Compila .exe sem janela de console
- Instala em `%LOCALAPPDATA%\FlipClock\`
- Cria atalho no menu iniciar

### Instalacao manual

Se preferir instalar manualmente, veja as instrucoes por OS:

<details>
<summary>Linux (manual)</summary>

```bash
go build -ldflags "-s -w" -o flipclock .
cp flipclock ~/.local/bin/
mkdir -p ~/.local/share/icons/hicolor/256x256/apps
cp images/flipclock.png ~/.local/share/icons/hicolor/256x256/apps/flipclock.png
cp flipclock.desktop ~/.local/share/applications/com.flipclock.app.desktop
gtk-update-icon-cache ~/.local/share/icons/hicolor/
update-desktop-database ~/.local/share/applications/
```

</details>

<details>
<summary>macOS (manual com fyne package)</summary>

```bash
go install fyne.io/tools/cmd/fyne@latest
fyne package -os darwin -icon images/flipclock.png -name FlipClock -appID com.flipclock.app
mv FlipClock.app /Applications/
```

</details>

<details>
<summary>Windows (manual com fyne package)</summary>

```bash
go install fyne.io/tools/cmd/fyne@latest
fyne package -os windows -icon images/flipclock.png -name FlipClock -appID com.flipclock.app
```

</details>

## Roadmap

- [x] Animacao flip (duas fases, 300ms ease-in-out)
- [x] Layout responsivo (proporcional ao tamanho da janela)
- [x] Fullscreen (F/F11 + menu tray)
- [x] Fonte customizada embutida (Bebas Neue)
- [x] Icone personalizado no app, janela e tray
- [ ] Toggle 12h/24h (via menu tray)
- [ ] Always-on-top
- [ ] Tema light mode
- [ ] Configuracoes persistidas (JSON)

## Como contribuir

1. Fork o repositorio
2. Crie uma branch para sua feature (`git checkout -b feature/minha-feature`)
3. Faca commit das mudancas (`git commit -m "feat: descricao da feature"`)
4. Push para a branch (`git push origin feature/minha-feature`)
5. Abra um Pull Request

### Convencoes

- Commits seguem [Conventional Commits](https://www.conventionalcommits.org/)
- Codigo, variaveis e comentarios em ingles
- Testes com `go test ./...`

## Creditos

- **Fonte:** [Bebas Neue](https://fonts.google.com/specimen/Bebas+Neue) por Ryoichi Tsunekawa (SIL Open Font License)
- **GUI:** [Fyne](https://fyne.io/) toolkit para Go

## Licenca

MIT
