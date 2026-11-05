# ZERO MM2

**Nandox** · Murder Mystery 2 · Luau · WindUI por padrão

Abre o MM2, liga o Real à partida e executa a linha abaixo. O botão **ZERO · Menu** e a tecla **Ctrl direito** mostram ou escondem a interface.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nandox97l/zero-mm2/main/zero-mm2.luau?t=" .. os.time()))()
```

| Aba | O que faz |
| --- | --- |
| Player | Mostra avatar, idade da conta, FPS e ping com cores, módulos carregados e APIs em falta. |
| Aimbot | Ajusta o campo de visão, o alvo, a suavidade e a previsão. Silent aim redireciona o disparo. O trigger bot ativa a pistola quando a mira encontra um alvo elegível, inclusive com aimbot ou silent aim. |
| Visuais | Identifica jogadores por papel, mostra nomes, caixas, esqueleto R6/R15, barra de vida colorida, destaques, moedas e a arma caída. |
| Ronda | Recolhe a pistola caída por teleporte, ativa a recolha automática e reúne as ações de terminar a ronda. A ação exclusiva do Murderer tenta atingir os adversários sem deslocar o personagem. A aceitação dos golpes depende do servidor. |
| Farm | Apanha moedas em voo, por baixo do chão ou por teleporte. No modo subterrâneo, o personagem regressa a um piso antes de esperar. O farm de XP tenta sobreviver à rodada. Com a mochila cheia podes esperar, dar reset, regressar ao lobby ou tentar vencer conforme o papel. |
| Movimento | Controla velocidade, potência do salto, salto infinito, voo e noclip. |
| Clipes | Salto duplo com FakeBomb, giro de câmara com disparo ao cruzar um alvo elegível, velocidade do giro e cancelamento. O salto requer o brinquedo FakeBomb e respeita um intervalo de 22 segundos. Inclui campo de visão da câmara entre 40 e 120 graus e iluminação clara, com reposição ao desligar ou fechar. O modo streamer oculta a identidade no painel, nos rótulos ESP e na seleção de alvos, além do chat e da lista padrão de jogadores. Interfaces próprias do jogo podem continuar a mostrar nomes. |
| Troll | Seleciona um jogador para observar, seguir ou orbitar. Inclui rotação, cores do personagem e fling experimental. |
| Skins | Galeria com miniaturas e pesquisa, limitada aos modelos que carregam. A montagem no cinto usa os attachments do próprio personagem e conserva a posição VIP/Elite. Só aparecem opções com recursos carregados e pega nativa observada. A orientação na mão usa a pega específica de cada skin. A biblioteca pública skins.json e a cache local ZERO-MM2-models-v1.json permitem reutilizar geometrias noutras partidas. Novos modelos recolhidos são guardados localmente. A biblioteca inicial cobre os modelos já recolhidos e validados, sem garantir todas as entradas do catálogo oficial. |
| Caixas | Seleciona uma caixa e a quantidade. Cada abertura aceite consome a moeda indicada pelo jogo. |
| Configurações | Escolhe WindUI, Rayfield Gen2 ou Fluent em Biblioteca da interface. A escolha fica guardada no Real. Também podes guardar e recuperar configurações e trocar entre português e inglês. |
| Sobre | Consulta a autoria, a biblioteca e os projetos de referência. |

O anti-AFK atua sobre o evento de inatividade quando o executor suporta esta operação. O recolhedor teletransporta o personagem para a pistola caída. Na ação automática de terminar a rodada, o Murderer procura os adversários e o Sheriff procura o Murderer. O Innocent pode esperar pela arma ou tentar o fling. Teleporte e voo rápido podem causar expulsão.

### Créditos

Interfaces [WindUI](https://github.com/Footagesus/WindUI), [Fluent](https://github.com/dawid-scripts/Fluent) e [Rayfield Gen2](https://sirius.menu/gen2). Referências de movimento e física [Infinite Yield](https://github.com/EdgeIY/infiniteyield) e [MonoMM2](https://github.com/fleecewtf/MonoMM2). Referências de farm, ESP e arma caída [MM2 AutoFarm](https://github.com/Zyn-ic/MM2-AutoFarm) e [OminousVibes](https://github.com/OminousVibes-Exploit/Scripts).

A pesquisa desta atualização incluiu [MM2 Utilities](https://github.com/Aluxis/MM2-Utilities), como referência de controlos de câmara e iluminação. A montagem das skins usa os modelos e as constraints observados no cliente MM2 v1461.

A biblioteca inicial inclui 37 geometrias, das quais 11 têm também pega nativa recolhida. A galeria exige ambas as informações e carregamento bem-sucedido. Estes números podem crescer com modelos e pegas encontrados nas partidas.
