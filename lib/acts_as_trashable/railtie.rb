module ActsAsTrashable
  class Railtie < Rails::Railtie
    rake_tasks do
      #Dir[File.expand_path('tasks/*.rake', __FILE__)].each { |f| p "** #{f}"; load f }
      load File.expand_path('../tasks/acts_as_trashable_tasks.rake', __FILE__)
    end
  end
end
