/// Web Client ID do projeto no Google Cloud Console (tipo "Aplicativo da Web").
/// É um identificador público, não um segredo. Precisa ser o MESMO valor do
/// `GOOGLE_CLIENT_ID` do servidor (`server/src/utils/google.js`). Se ficar
/// vazio, o botão "Google" avisa que o login está indisponível.
const googleWebClientId = '954272668229-hrcersad8banluij7r90eis9t2jbp2u6.apps.googleusercontent.com';

/// Client ID do tipo "iOS" no Google Cloud Console. Só é usado no iOS — no
/// Android o Google Sign-In se resolve pelo pacote + SHA-1 cadastrados no
/// Play Console, sem precisar desse valor no app.
const googleIosClientId = '954272668229-sor6r36d79m8r0b8qdfgq48ajr348sv2.apps.googleusercontent.com';
