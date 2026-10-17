require "../../spec_helper"

describe Publishing::Storage::Migrations do
  it "creates the publishing schema and seeds the initial categories" do
    database = publishing_test_database
    begin
      Publishing::Storage::Migrations.apply(database)

      categories = database.query_all("SELECT name, slug FROM categories ORDER BY name", as: {name: String, slug: String})
      categories.map(&.[:slug]).should eq(["gaming", "programming"])
      database.query_one("SELECT COUNT(*) FROM schema_migrations", as: Int64).should eq(1_i64)
    ensure
      database.close
    end
  end

  it "is idempotent" do
    database = publishing_test_database
    begin
      Publishing::Storage::Migrations.apply(database)
      Publishing::Storage::Migrations.apply(database)

      database.query_one("SELECT COUNT(*) FROM categories", as: Int64).should eq(2_i64)
      database.query_one("SELECT COUNT(*) FROM schema_migrations", as: Int64).should eq(1_i64)
    ensure
      database.close
    end
  end
end
