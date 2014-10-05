default["stalltalk"]["user"] = "stalltalk"
default["stalltalk"]["group"] = "stalltalk"

# SSH
default["stalltalk"]["authorized_keys"] = []

# PROJECT
default["stalltalk"]["project_path"] = "/home/#{node["stalltalk"]["user"]}/Projects/stalltalk"
default["stalltalk"]["virtualenv_path"] = "/home/#{node["stalltalk"]["user"]}/.virtualenvs/stalltalk"

# REPOS
default["stalltalk"]["git"]["repository"] = "git@github.com:sectioneleven/stalltalk.git"
default["stalltalk"]["git"]["reference"] = "master"

# UWSGI
default["stalltalk"]["uwsgi"]["socket"] = "/tmp/stalltalk.sock"
default["stalltalk"]["uwsgi"]["socket_type"] = "unix"  # or tcp

# NGINX
default["stalltalk"]["domain_names"] = ["stalltalk.net"]

# ENV
default["stalltalk"]["db_host"] = ""
default["stalltalk"]["db_name"] = ""
default["stalltalk"]["db_user"] = ""
default["stalltalk"]["db_pass"] = ""
default["stalltalk"]["email_use_tls"] = "True"
default["stalltalk"]["email_host"] = "smtp.gmail.com"
default["stalltalk"]["email_host_user"] = "admin@secioneleven.org"
default["stalltalk"]["email_host_password"] = ""
default["stalltalk"]["email_port"] = 587
default["stalltalk"]["raven_dsn"] = ""
default["stalltalk"]["google_analytics_tracking_id"] = "UA-45590724-1"
default["stalltalk"]["rfp_notification_email_to"] = []
default["stalltalk"]["property_notification_email_to"] = []
