# ADW modified: Added methods to disable trash collection *globally* instead of per instance.
# Modified #destroy_with_trash to use this method to prevent the creation of redundant trash records
# (when a record and its children are both acts_as_trashable).

require 'active_record'
require 'active_support/all'

module ActsAsTrashable
  
  autoload :TrashRecord, File.expand_path('../acts_as_trashable/trash_record', __FILE__)
  
  def self.included (base)
    base.extend(ActsMethods)
  end
  
  module ActsMethods
    # Class method that injects the trash behavior into the class.
    def acts_as_trashable
      extend ClassMethods
      include InstanceMethods
      alias_method_chain :destroy, :trash
    end
  end
  
  module ClassMethods
    # Empty the trash for this class of all entries older than the specified maximum age in seconds.
    def empty_trash (max_age)
      TrashRecord.empty_trash(max_age, :only => self)
    end
    
    # Restore a particular entry by id from the trash into an object in memory. The record will not be saved.
    def restore_trash (id)
      trash = TrashRecord.find_trash(self, id)
      return trash.restore if trash
    end
    
    # Restore a particular entry by id from the trash, save it, and delete the trash entry.
    def restore_trash! (id)
      trash = TrashRecord.find_trash(self, id)
      return trash.restore! if trash
    end

    def acts_as_trashable_disabled
      @@acts_as_trashable_disabled ||= false
    end
  
    def disable_trash
      save_val = @@acts_as_trashable_disabled
      begin
        @@acts_as_trashable_disabled = true
        yield if block_given?
      ensure
        @@acts_as_trashable_disabled = save_val
      end          
    end
  end
  
  module InstanceMethods
    def destroy_with_trash
      return destroy_without_trash if @acts_as_trashable_disabled || self.class.acts_as_trashable_disabled 
      TrashRecord.transaction do
        trash = TrashRecord.new(self)
        trash.save!
	self.class.disable_trash do
          return destroy_without_trash
	end
      end
    end
    
    # Call this method to temporarily disable the trash feature within a block.
    def disable_trash
      save_val = @acts_as_trashable_disabled
      begin
        @acts_as_trashable_disabled = true
        yield if block_given?
      ensure
        @acts_as_trashable_disabled = save_val
      end
    end
  end
  
end

ActiveRecord::Base.send(:include, ActsAsTrashable)
