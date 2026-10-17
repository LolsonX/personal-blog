CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL
);

CREATE TABLE posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  summary TEXT NOT NULL DEFAULT '',
  body_markdown TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published')),
  first_published_at INTEGER,
  slug_frozen INTEGER NOT NULL DEFAULT 0 CHECK (slug_frozen IN (0, 1)),
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  CHECK (status != 'published' OR first_published_at IS NOT NULL),
  CHECK (slug_frozen = 0 OR first_published_at IS NOT NULL)
);

CREATE TABLE post_categories (
  post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
  PRIMARY KEY (post_id, category_id)
);

CREATE INDEX posts_published_by_date
  ON posts(status, first_published_at DESC)
  WHERE status = 'published';

CREATE INDEX post_categories_by_category ON post_categories(category_id, post_id);

INSERT INTO categories (name, slug, created_at)
VALUES ('Programming', 'programming', CAST(strftime('%s', 'now') AS INTEGER));

INSERT INTO categories (name, slug, created_at)
VALUES ('Gaming', 'gaming', CAST(strftime('%s', 'now') AS INTEGER));
