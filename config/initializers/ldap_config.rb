# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

source = ERB.new(File.read(Rails.root.join("config/ldap.yml").to_s)).result
ldap_config = if defined?(Psych::VERSION) && Psych::VERSION > "4.0"
  YAML.unsafe_load(source)[Rails.env]
else
  YAML.load(source)[Rails.env]
end

SheffieldLdapLookup::LdapFinder.ldap_config = ldap_config
::Devise.ldap_use_admin_to_bind = true
::Devise.ldap_config = lambda {
  config = ldap_config.dup
  config["admin_user"] = config.delete("username")
  config["admin_password"] = config.delete("password")
  config
}
