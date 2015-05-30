default["stalltalk"]["user"] = "ubuntu"
default["stalltalk"]["group"] = "ubuntu"

# SSH
default["stalltalk"]["authorized_keys"] = []

# PROJECT
default["stalltalk"]["project_name"] = "stalltalk"
default["stalltalk"]["project_path"] = "/home/#{node["stalltalk"]["user"]}/Projects/#{node["stalltalk"]["project_name"]}"
default["stalltalk"]["virtualenv_path"] = "/home/#{node["stalltalk"]["user"]}/.virtualenvs/#{node["stalltalk"]["project_name"]}"

# REPOS
default["stalltalk"]["git"]["repository"] = "git@github.com:sectioneleven/stalltalk.git"
default["stalltalk"]["git"]["reference"] = "master"

# UWSGI
default["stalltalk"]["uwsgi"]["socket"] = "/tmp/#{node["stalltalk"]["project_name"]}.sock"
default["stalltalk"]["uwsgi"]["socket_type"] = "unix"  # or tcp

# NGINX
default["stalltalk"]["domain_names"] = ["stalltalk.net"]
default["stalltalk"]["nginx_default_server?"] = false

default["nginx"]["gzip_vary"] = "on"

# ENV
default["stalltalk"]["site_id"] = 1
default["stalltalk"]["allowed_hosts"] = node["stalltalk"]["domain_names"]
default["stalltalk"]["db_host"] = "127.0.0.1"
default["stalltalk"]["db_port"] = "5432"
default["stalltalk"]["db_name"] = "geotalk"
default["stalltalk"]["db_user"] = "geotalk"
default["stalltalk"]["db_pass"] = "g30t41k-p4ssw0rd"
default["stalltalk"]["email_use_tls"] = "True"
default["stalltalk"]["email_host"] = "smtp.gmail.com"
default["stalltalk"]["email_host_user"] = "admin@sectioneleven.org"
default["stalltalk"]["email_host_password"] = ""
default["stalltalk"]["email_port"] = 587
default["stalltalk"]["raven_dsn"] = ""
default["stalltalk"]["google_analytics_tracking_id"] = "UA-45590724-1"
default["stalltalk"]["rfp_notification_email_to"] = []
default["stalltalk"]["property_notification_email_to"] = []
default["stalltalk"]["celery_redis_host"] = "127.0.0.1"
default["stalltalk"]["celery_redis_port"] = 6379
default["stalltalk"]["default_file_storage"] = ""
default["stalltalk"]["staticfiles_storage"] = ""
default["stalltalk"]["aws_access_key_id"] = ""
default["stalltalk"]["aws_secret_access_key"] = ""
default["stalltalk"]["aws_storage_bucket_name"] = ""

default["stalltalk"]["admin_user"] = "admin"
default["stalltalk"]["admin_pass"] = "4dm1n"
default["stalltalk"]["admin_email"] = "admin@example.com"
