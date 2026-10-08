# NXWeb

Navegador simples para homebrew do Nintendo Switch. Marco atual: **abrir páginas da internet** (HTML + CSS, sem imagens e sem JavaScript ainda).

| Camada | Peça |
|---|---|
| HTML/CSS e layout | [litehtml](https://github.com/litehtml/litehtml) (fixado em `v0.8`) |
| Desenho | SDL2 + SDL2_ttf (fonte do próprio sistema do Switch) |
| Rede / HTTPS | libcurl + mbedtls (certificados em `romfs/cacert.pem`) |
| Build | devkitPro (devkitA64 + libnx), GitHub Actions |

## Compilar pelo GitHub (sem instalar nada)

1. Suba esta pasta para um repositório no GitHub (branch `main`).
2. Abra a aba **Actions**. O workflow `Build NRO` roda a cada push.
3. Quando terminar, baixe o artefato `nxweb` (contém `nxweb.nro`).
4. Para publicar uma release, crie uma tag: `git tag v0.1.0 && git push --tags`.

## Compilar localmente

```bash
# requer devkitPro com devkitA64 e libnx
sudo dkp-pacman -S $(grep -v '^#' scripts/packages.txt)

bash scripts/fetch-deps.sh   # baixa litehtml e o cacert.pem
make -j$(nproc)
```

### Local com Docker (Linux, macOS ou WSL)

```bash
bash scripts/fetch-deps.sh
docker run --rm -v "$PWD":/data -w /data devkitpro/devkita64 bash -c \
  "dkp-pacman -Sy --noconfirm && dkp-pacman -S --needed --noconfirm $(grep -v '^#' scripts/packages.txt | tr '\n' ' ') && make -j"
```

## Se o Actions falhar com erro 403 do dkp-pacman

O servidor `pkg.devkitpro.org` às vezes recusa pacman vindo de CI. O workflow já tenta de novo com espera e guarda as bibliotecas em cache (o pacman só roda quando o cache está vazio). Se mesmo assim falhar, rode o build local com Docker (acima): o artefato `nxweb.nro` sai na pasta do projeto.

## Instalar no console

Copie `nxweb.nro` para `sd:/switch/` e abra pelo Homebrew Menu (precisa de custom firmware).
Dica: abrir o homebrew segurando **R** sobre um jogo (modo "title takeover") dá bem mais memória do que abrir pelo álbum (modo applet).

## Controles

| Botão | Ação |
|---|---|
| Analógico esquerdo | mover o ponteiro (empurra a página nas bordas) |
| **A** | clicar no que está sob o ponteiro |
| D-pad ↑/↓, analógico direito | rolar |
| ZL / ZR | página acima / abaixo |
| **Y** | digitar URL ou busca (teclado do sistema) |
| **X** | recarregar |
| **B** ou **L** / **R** | voltar / avançar |
| **−** | página inicial |
| **+** | sair |
| Toque | tocar = clicar, arrastar = rolar, tocar na barra de cima = digitar URL |

Texto sem ponto ou com espaço vira busca no DuckDuckGo (versão HTML).

## Estrutura

```
source/main.cpp        loop principal, controles, navegação, histórico
source/container.cpp   ponte litehtml -> SDL2 (fontes, texto, cores, bordas, CSS externo)
source/http.cpp        GET com libcurl, resolução de URLs
romfs/master.css       estilo padrão do navegador
scripts/fetch-deps.sh  baixa litehtml e certificados
.github/workflows/     build automático
```

## Limitações conhecidas (v0.1)

- Sem imagens (`<img>` ocupa 0x0) e sem JavaScript.
- Carregamento bloqueia a interface (a rede roda na thread principal).
- Bordas só retangulares; sem gradientes nem imagens de fundo.
- Âncoras internas (`#id`) e formulários ainda não funcionam.
- Só UTF-8 e Latin-1/cp1252.

## Se o primeiro build falhar

O código do `container.cpp` foi escrito para a API do litehtml `v0.8` e **ainda não foi compilado**. A API do litehtml muda entre versões, então o provável erro é de assinatura (`marked 'override' but does not override`) ou de nome de campo. Copie o log do Actions e ajuste o método indicado. Para trocar a versão, defina `LITEHTML_TAG` em `scripts/fetch-deps.sh`.

## Próximos passos

1. Imagens: baixar com curl, decodificar (libpng/libjpeg-turbo/libwebp) e implementar `load_image`, `get_image_size` e backgrounds.
2. Rede em thread separada, com indicador de progresso e cancelamento.
3. Abas, favoritos e histórico persistido no SD.
4. Âncoras `#id`, formulários simples e busca na página.
5. JavaScript (QuickJS-ng) com bindings de DOM.
