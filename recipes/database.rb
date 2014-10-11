include_recipe "postgresql::server"
include_recipe "database::postgresql"

database_connection_info = {
  :host => node["stalltalk"]["db_host"],
  :port => node["stalltalk"]["db_port"],
  :username => "postgres",
  :password => node["postgresql"]["password"]["postgres"]
}

postgresql_database_user node["stalltalk"]["db_user"] do
  connection database_connection_info
  password node["stalltalk"]["db_pass"].empty? ? Chef::EncryptedDataBagItem.load("stalltalk", "passwords")[node.chef_environment]["database"] : node["stalltalk"]["db_pass"]
  action :create
end

postgresql_database node["stalltalk"]["db_name"] do
  connection database_connection_info
  owner node["stalltalk"]["db_user"]
  action :create
end

pgconn_info = database_connection_info.merge(
  :user => database_connection_info[:username],
  :dbname => node["stalltalk"]["db_name"]
)
pgconn_info.delete(:username)

postgresql_database "create postgis extension" do
  connection database_connection_info
  database_name node["stalltalk"]["db_name"]
  sql "CREATE EXTENSION postgis"
  action :query
  not_if do
    db = ::PGconn.new(pgconn_info)
    created = db.query("SELECT * FROM pg_extension WHERE extname = 'postgis'").num_tuples != 0
    db.close rescue nil
    created
  end
end

postgresql_database "create postgis_topology extension" do
  connection database_connection_info
  database_name node["stalltalk"]["db_name"]
  sql "CREATE EXTENSION postgis_topology"
  action :query
  not_if do
    db = ::PGconn.new(pgconn_info)
    created = db.query("SELECT * FROM pg_extension WHERE extname = 'postgis_topology'").num_tuples != 0
    db.close rescue nil
    created
  end
end
