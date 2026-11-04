# ZERO MM2

**Nandox** · Murder Mystery 2 · Luau · WindUI por padrão

Abre o MM2, liga o Real à partida e executa a linha abaixo. O botão **ZERO · Menu** e a tecla **Ctrl direito** mostram ou escondem a interface.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nandox97l/zero-mm2/main/zero-mm2.luau"))()
```

| Aba | O que faz |
| --- | --- |
| Player | Mostra avatar, idade da conta, FPS e ping com cores, módulos carregados e APIs em falta. |
| Aimbot | Ajusta o campo de visão, o alvo, a suavidade e a previsão. Silent aim redireciona o disparo. O trigger bot ativa a pistola quando a mira encontra um alvo elegível, inclusive com aimbot ou silent aim. Como Murderer, podes iniciar a eliminação de todos os adversários vivos. |
| Visuais | Identifica jogadores por papel, mostra nomes, caixas, esqueleto R6/R15, destaques, moedas e a arma caída. |
| Farm | Apanha moedas em voo, por baixo do chão ou por teleporte. No modo subterrâneo, o personagem regressa a um piso antes de esperar. O farm de XP tenta sobreviver à rodada. Com a mochila cheia podes esperar, dar reset, regressar ao lobby ou tentar vencer conforme o papel. |
| Movimento | Controla velocidade, potência do salto, salto infinito, voo e noclip. |
| Troll | Seleciona um jogador para observar, seguir ou orbitar. Inclui rotação, cores do personagem e fling experimental. |
| Skins | Escolhe a inicial e a skin no catálogo completo de facas e pistolas do jogo. A seleção ativa o efeito local. O script procura primeiro a geometria disponível no jogo e, quando necessário, uma versão pública gratuita na Creator Store. Se o modelo 3D estiver indisponível, o painel indica-o. Personaliza material, cor e efeito visual no cliente. O inventário mantém os itens originais. |
| Caixas | Seleciona uma caixa e a quantidade. Cada abertura aceite consome a moeda indicada pelo jogo. |
| Configurações | Escolhe WindUI, Rayfield Gen2 ou Fluent em Biblioteca da interface. A escolha fica guardada no Real. Também podes guardar e recuperar configurações e trocar entre português e inglês. |
| Sobre | Consulta a autoria, a biblioteca e os projetos de referência. |

O anti-AFK atua sobre o evento de inatividade quando o executor suporta esta operação. O recolhedor teletransporta o personagem para a pistola caída. Ao tentar terminar a rodada, o Murderer procura os adversários e o Sheriff procura o Murderer. O Innocent pode esperar pela arma ou tentar o fling. Teleporte e voo rápido podem causar expulsão.

### Créditos

Interfaces [WindUI](https://github.com/Footagesus/WindUI), [Fluent](https://github.com/dawid-scripts/Fluent) e [Rayfield Gen2](https://sirius.menu/gen2). Referências de movimento e física [Infinite Yield](https://github.com/EdgeIY/infiniteyield) e [MonoMM2](https://github.com/fleecewtf/MonoMM2). Referências de farm, ESP e arma caída [MM2 AutoFarm](https://github.com/Zyn-ic/MM2-AutoFarm) e [OminousVibes](https://github.com/OminousVibes-Exploit/Scripts).
