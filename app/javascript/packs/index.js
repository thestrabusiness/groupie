import { Elm } from '../Main.elm';

const { API_TOKEN } = process.env;

document.addEventListener('DOMContentLoaded', () => {
  Elm.Main.init({
    node: document.getElementById('main'),
    flags: { token: "token" }
  });
})

