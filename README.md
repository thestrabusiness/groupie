# Dependencies

* Ruby 2.6.5
* Rails 6.0.3.2
* Elm 0.19.1
* Postgres

# Running Locally

Clone the repo and `bundle install` in the root directory

`rails db:setup`

`yarn install` to setup webpack dependencies

`foreman start -f Procfile.dev` to run rails server and webpack-dev-server together

Visit `localhost:3000` to see the application

