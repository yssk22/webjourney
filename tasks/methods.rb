#
# Launch couchapp push command
#
def couchapp_push(dir, uri)
  begin
    sh("couchapp push --verbose #{dir} #{uri}")
  rescue => e
    # ignore 255 exit code from couchapp 0.5
    if $?.to_i >> 8 != 255
      raise e
    end
  end
end

#
# Returns true when str is nil or empty.
#
def blank?(str)
  str.nil? || str == ""
end

#
# Returns the specified container directory path.
#
def container_dir(container)
  File.join(File.dirname(__FILE__), "../relax/containers/#{container}")
end

#
# Returns the specified app directory path.
#
def gadget_dir(app)
  File.join(File.dirname(__FILE__), "../relax/gadgets/#{app}")
end

#
# Create a database with confirmations.
#
def init_database(db)
  step "Database Check" do
    if db.exist?
      confirmed = confirm("Continue with dropping database?") do
        puts "Drop the database."
        db.drop
      end
      unless confirmed
        puts "Initialization canceled."
        exit 0
      end
    end
    puts "Create a database."
    db.create
  end
end

#
# Import data setes under the <tt>dir</tt>
#
def import_dataset(db, dir)
  step("Import Data Sets") do
    Dir.glob(File.join(dir, "**/*.json")) do |fname|
      docs = nil
      if fname =~ /.*\.test\.json/
        docs = db.insert_fixtures(fname) if IMPORT_TEST_FIXTURES
      else
        docs = db.import_from_file(fname)
      end
      if docs
        puts "[INFO] Importing #{File.basename(fname)} - #{docs.length} documents"
      end
    end
  end
end

#
# Execute the block with announcing the step description.
#
def step(step, &block)
  puts "*** #{step}"
  block.call()
  puts ""
end

#
# Execute the block with the y/n confirmation.
#
def confirm(msg, &block)
  if ENV["FORCE"] == "true"
    puts "#{msg} [y/n]y"
    block.call()
    return true
  end
  print "#{msg} [y/n]"
  c = $stdin.gets().chomp!
  case c
  when "y"
    block.call()
    return true
  when "n"
    return false
  else
    puts "Please input y or n."
    confirm(msg, &block)
  end
end
