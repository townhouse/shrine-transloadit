require "bundler/setup"

require "minitest/autorun"
require "minitest/pride"

require "minitest/hooks/default"

require "shrine"
require "shrine/storage/s3"

require "dotenv"

Dotenv.load!

Shrine.plugin :sequel
Shrine.plugin :versions
Shrine.plugin :transloadit,
  auth_key:    ENV.fetch("TRANSLOADIT_AUTH_KEY"),
  auth_secret: ENV.fetch("TRANSLOADIT_AUTH_SECRET")

s3 = Shrine::Storage::S3.new(
  bucket:            ENV.fetch("S3_BUCKET"),
  region:            ENV.fetch("S3_REGION"),
  access_key_id:     ENV.fetch("S3_ACCESS_KEY_ID"),
  secret_access_key: ENV.fetch("S3_SECRET_ACCESS_KEY"),
)

Shrine.storages = {cache: s3, store: s3}

DB = Sequel.sqlite
DB.create_table :records do
  primary_key :id
  column :attachment_data, :text
end

Sequel.cache_anonymous_models = false

class Minitest::Test
  def setup
    shrine_class = Class.new(Shrine)
    Object.const_set(:Record, Sequel::Model(:records))
    Record.include shrine_class[:attachment]
    @record = Record.new
    super
  end

  def teardown
    super
    Record.dataset.delete
    Object.send(:remove_const, :Record)
  end

  def image
    File.open("test/fixtures/image.jpg")
  end
end
