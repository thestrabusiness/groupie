# Dependencies

* Ruby 2.6.5
* Rails 6.0.3.2
* Elm 0.19.1
* Postgres
* elm-format

# Running Locally

Clone the repo and `bundle install` in the root directory

`rails db:setup`

`yarn install` to setup webpack dependencies

`foreman start -f Procfile.dev` to run rails server and webpack-dev-server together

Visit `localhost:3000` to see the application

# Working with GroupMe applicaitons and authentication

You'll need to setup a GroupMe account (if you don't already have one) and set up an application to use for development: https://dev.groupme.com/applications

In order to authenticate via your GroupMe account when developing, you should set up [nrgrok](https://github.com/inconshreveable/ngrok).

Once install you can run `nrgok http 3000` with the rails server running. You'll see two addresses (one http and https) that ngrok will use to forward your traffic. 

Copy the https address into your GroupMe application's callback URL, appending `/auth/callback` to it. It'll end up looking something like:
`https://69128d9fd826.ngrok.io/auth/callback`

Once everything is configure, and with the rails server and ngrok running together, you'll be able to authenticate via the GroupMe API.
