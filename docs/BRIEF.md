# FlipClock - Brief

> Widget desktop de relógio flip clock minimalista

**Data:** 20/02/2026
**Status:** 🚀 In Development

---

## 🎯 Problema

Não existe um relógio desktop flip clock simples, bonito e sem overhead — a maioria é app web, requer Electron ou não tem visual minimalista dark mode.

## ✨ Solução

Widget desktop leve em Go + Fyne: janela borderless arrastável, fundo preto, dígitos grandes cinza, sistema de tray para manter rodando em background.

## 👥 Público-Alvo

Desenvolvedores e power users que gostam de ter o relógio visível no desktop com estética terminal/dark, sem abrir browser.

## 🚀 Proposta de Valor

- **Leve:** binário único ~10MB, zero dependências de runtime
- **Cross-platform:** Linux, macOS, Windows (mesmo código)
- **Minimalista:** sem configuração, sem bloat
- **Tray-aware:** minimiza para tray, nunca mata o processo

## ⏱️ MVP Scope

**IN:**
- Janela borderless, fundo #000000
- Cards HH / MM com fonte grande cinza
- Segundos pequenos (canto inferior direito)
- AM/PM (canto inferior esquerdo)
- Update loop a cada segundo
- Drag-to-move no corpo da janela
- Tray icon com menu Mostrar / Fechar
- Fechar/Esc → minimiza para tray

**OUT:**
- Animação flip real (TODO preparado no código)
- Configurações de cor/formato
- Múltiplos temas
- Alarmes

## 📊 Sucesso

Binário compilado, rodando em background, visual fiel às referências dark mode.
