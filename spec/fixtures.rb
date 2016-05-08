ActiveRecord::Schema.define :version => 0 do
  create_table :users, force: true do |t|
    t.string :name
    t.boolean :confirmed
    t.integer :department_id
  end

  create_table :departments, force: true do |t|
    t.string :name
    t.integer :university_id
  end

  create_table :universities, force: true do |t|
    t.string :name
  end

  create_table :followings, force: true do |t|
    t.integer :follower_id
    t.integer :followee_id
  end
end

Dir[File.join(File.dirname(__FILE__), 'fixtures/**/*.rb')].each{ |f| require f }
