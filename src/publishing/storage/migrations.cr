require "set"

module Publishing
  module Storage
    module Migrations
      MIGRATIONS = {
        1_i64 => {{ read_file("src/publishing/storage/migrations/001_initial_schema.sql") }},
      }

      def self.apply(database : DB::Database) : Nil
        database.exec(<<-SQL)
          CREATE TABLE IF NOT EXISTS schema_migrations (
            version INTEGER PRIMARY KEY,
            applied_at INTEGER NOT NULL
          )
          SQL

        applied = database.query_all("SELECT version FROM schema_migrations", as: Int64).to_set

        MIGRATIONS.each do |version, migration_sql|
          next if applied.includes?(version)

          database.transaction do |transaction|
            migration_sql.split(';').each do |statement|
              statement = statement.strip
              transaction.connection.exec(statement) unless statement.empty?
            end
            transaction.connection.exec(
              "INSERT INTO schema_migrations (version, applied_at) VALUES (?, ?)",
              version,
              Time.utc.to_unix
            )
          end
        end
      end
    end
  end
end
