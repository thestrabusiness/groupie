import { Elm } from '../Main.elm';

document.addEventListener('DOMContentLoaded', () => {
  Elm.Main.init({
    node: document.getElementById('main'),
    flags: { clientId: process.env.CLIENT_ID  }
  });
})

