namespace :change_fiddle do

  desc 'Migrate the containers to the new db structure'
  task add_enum: :environment do
    Fiddle.all.each do |fiddle|
      fiddle.update_flag = fiddle.update_flag.eql? 0 ? 1 : 0
      fiddle.code_type = 0
      fiddle.save!
    end
  end

end