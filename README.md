# Say for Me - App de Comunicação
Aplicativo Inteligente de Comunicação Alternativa para Pessoas com TEA: Uma Abordagem Personalizada com Inteligência Artificial

[Imagem da interface da aplicação]

# 📝 Índice
Sobre o Projeto

✨ Funcionalidades Principais

📸 Capturas de Ecrã

🚀 Tecnologias Utilizadas

🏁 Como Começar

📁 Estrutura do Projeto

🛣️ Próximos Passos (Roadmap)

👩‍💻 Autora

📜 Licença

🙏 Agradecimentos

🌎 Sobre o Projeto
O Say for Me é uma aplicação de Comunicação Aumentativa e Alternativa (CAA) desenvolvida para facilitar a comunicação de pessoas com dificuldades na fala, especialmente aquelas com Transtorno do Espectro Autista (TEA). Este projeto foi desenvolvido como um Trabalho de Conclusão de Curso de Engenharia de Computação na Universidade Tecnológica Federal do Paraná (UTFPR) - Campus Apucarana.

A aplicação serve como uma plataforma robusta, personalizável e performática, que permitirá, em fases futuras, a implementação e comparação de modelos de Inteligência Artificial para a sugestão de pictogramas.

✨ Funcionalidades Principais
Prancha Dinâmica e Híbrida: A tela principal pode exibir uma mistura de pastas (categorias) e pictogramas individuais, totalmente personalizável pelo utilizador.

Modo de Edição Intuitivo: Um simples interruptor na tela principal ativa o modo de edição, permitindo ao utilizador ativar/desativar itens (com um toque) e reordená-los (arrastando e soltando).

Gestão de Vocabulário: Uma área de configurações dedicada permite criar, editar e apagar categorias, bem como adicionar novos pictogramas a partir da base de dados do ARASAAC.

Cores da Chave de Fitzgerald: Os pictogramas são coloridos automaticamente com base no seu tipo gramatical (ex: verde para verbos, amarelo para pessoas), utilizando os metadados da API do ARASAAC.

Síntese de Voz (TTS): Lê as palavras selecionadas ou frases completas para facilitar a comunicação verbal.

Funcionalidade Offline: Um banco de dados local SQLite armazena todo o vocabulário (pictogramas e categorias), enquanto um cache de imagens permite a visualização sem ligação à internet.

Base para IA: A arquitetura atual foi projetada para ser a fundação para a implementação de modelos de IA de previsão de pictogramas.

📸 Capturas de Ecrã
Tela Principal

Modo Edição

Vista de Pasta

[Imagem da tela principal]

[Imagem do modo de edição]

[Imagem da vista de uma pasta]

🚀 Tecnologias Utilizadas
Este projeto foi desenvolvido com as seguintes tecnologias e bibliotecas principais:

Flutter: Um toolkit de UI desenvolvido pela Google para criar aplicações nativas para mobile, web e desktop a partir de uma única base de código.

Dart: A linguagem de programação utilizada para o desenvolvimento com Flutter.

SQFlite: Um banco de dados relacional para Flutter, utilizado para o armazenamento local do vocabulário.

Shared Preferences: Para guardar configurações simples do utilizador.

Cached Network Image: Para descarregar e armazenar em cache as imagens dos pictogramas.

Reorderable Grid View: Biblioteca para implementar a funcionalidade de arrastar e soltar no modo de edição.

HTTP: Para a comunicação com a API do ARASAAC.

Flutter TTS: Para implementar a funcionalidade de Text-to-Speech.

🏁 Como Começar
Para executar este projeto localmente, siga estes passos:

Pré-requisitos

Certifique-se de que tem o SDK do Flutter instalado na sua máquina.

Instalação

Clone este repositório:

git clone [https://github.com/seu-utilizador/say-for-me.git](https://github.com/seu-utilizador/say-for-me.git)

Navegue para o diretório do projeto:

cd say-for-me

Instale as dependências:

flutter pub get

Execução

Conecte um dispositivo ou inicie um emulador.

Execute o seguinte comando para iniciar a aplicação:

flutter run
