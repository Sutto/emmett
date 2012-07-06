# Emmett

Emmett is a tool named after Dr Emmett Brown from Back to the Future.

It's purpose is simple - given an index page and a bunch of API documents, it'll take
them and generate a nice, usable website people can use to consume the documentation.

It doesn't automate the docs or the like - it just does the simplest thing possible.

## Installation

Add this line to your application's Gemfile:

    gem 'emmett'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install emmett

## Usage

Emmett is primarily intended to be used as a rake task.

### Emmett + Rails

Want to generate the documentation directly in your application?

To configure it, the following options are available - simply put them in
`config/application.rb` and change them as fit:

```ruby
config.emmett.name        = "Your App"
config.emmett.index_page  = "doc/api.md" # Relative to doc/
config.emmett.section_dir = "doc/api" # Relative to doc/
config.emmett.output_dir  = "doc/generated-api"
config.emmett.template    = :default
```

It will use sane defaults (all being the same as above except the name, which is
the rails root dir titleize. I do suggest changing this). In Rails, it will
be available via `rake doc:api`.

### Emmett on it's own.

Likewise, you can use emmett inside any application thanks to the Rake Task.

In your Rakefile, simply add:

```ruby
require 'emmett/rake_task'

Emmett::RakeTask.new :docs do |t|
  t.name        = "Your App"
  t.index_page  = "api.md"
  t.section_dir = "api"
  t.output_dir  = "output"
  t.template    = :default
end
```

Like the rails version, this will use the values above as output,
with the name being based on the current directory name.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
