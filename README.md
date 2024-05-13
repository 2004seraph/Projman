# Projman

A group project orchestrator and management system, developed for the University of Sheffield as part of Software Hut \[COM3420\].

## Usage

This system requires:

- Ubuntu 22.04 LTS
- PostgreSQL
- `ruby-3.1.2` installed via `rvm`
- Rails 7

Account sign-ins will only work if both the server and client are connected to the University of Sheffield's VPN.

### To run the app locally

#### Setup

- Have PostgreSQL running:
  `sudo service postgresql start`

- Set up the app, this will install all dependancies, and create and seed the database:
  `./INSTALL.sh`

#### Adding your account

Our system uses the UoS SSO, your Muse login, but you must already exist in the database to sign in. You can now add yourself as either a member of staff or a student with the rails console.

You may add yourself as both a student and a member of staff, but you will simply be treated as a member of staff.

```bash
# from within the repositiory root
rails c
```
From within the rails console:
```ruby
# even if you're a student, adding your email to the staff table will allow you to log in as a staff member with your muse credentials
DatabaseHelper.create_staff("your_email@sheffield.ac.uk")

# keep in mind your username and email must be unique to be added to the database
DatabaseHelper.create_student({
  username: "YourMuseUsername",
  forename: "YourName",
  surname:  "YourSurname",
  title:    "Ms",
  email:    "your_email@sheffield.ac.uk"
})
```

After adding yourself to the database, you're ready to test the app.

#### Starting the app

- Run the app:
  `RAILS_ENV=development ./BOOT.sh`

- Visit [http://127.0.0.1:3000](http://127.0.0.1:3000)

### To deploy the app to production

We use Capistrano for our deployments, and interact with the production server via EpiGenesys' `epi_deploy` gem. To deploy the app:

- Ensure there are no changes to commit, that the working tree is clean. If so, use `git restore .` to undo all of them, or commit them.
- Run `./DEPLOY.sh`

## Maintainers

- Adam Willis <awillis4@sheffield.ac.uk>
- Jakub Bala <jbala1@sheffield.ac.uk>
- Joshua Henson <jhenson2@sheffield.ac.uk>
- Sam Taseff <sgttaseff1@sheffield.ac.uk>
- Oliver Pickford <opickford1@sheffield.ac.uk>
- Nahyan Khan <nkhan10@sheffield.ac.uk>
- Mathew Salkeld <msalkeld1@sheffield.ac.uk>
- Jack Edwards <jgedwards1@sheffield.ac.uk>
