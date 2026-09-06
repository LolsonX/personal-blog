require "sqlite3"

module Database
  @@db : DB::Database?

  DEFAULT_PATH = "./data/core-code.db"

  def self.connection : DB::Database
    @@db ||= begin
      ensure_storage_dir
      DB.open(ENV.fetch("DATABASE_URL", "sqlite3://#{DEFAULT_PATH}?journal_mode=wal&busy_timeout=5000&foreign_keys=on"))
    end
  end

  def self.healthy? : Bool
    connection.scalar("SELECT 1") == 1
  end

  private def self.ensure_storage_dir
    path = ENV.fetch("DATABASE_URL", DEFAULT_PATH)
    dir = File.dirname(path.sub(/\Asqlite3:\/\//, "").split("?").first)
    Dir.mkdir_p(dir) unless dir.empty?
  end
end
