import { Elm } from '../../elm/Main.elm';

document.addEventListener('DOMContentLoaded', () => {
  const authenticityToken = document.getElementsByName('csrf-token')[0].content

  Elm.Main.init({
    node: document.getElementById('main'),
    flags: {
      authenticityToken,
      clientId: process.env.CLIENT_ID
    }
  });
})

