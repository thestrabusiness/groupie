import { Elm } from '../Main.elm';

document.addEventListener('DOMContentLoaded', () => {
  Elm.Main.init({
    node: document.getElementById('main'),
    flags: { token: process.env.API_TOKEN, clientId: process.env.CLIENT_ID  }
  });
})

