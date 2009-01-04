module ActiveRecord
  module ConnectionAdapters
    module DataStatements
      # insert a record
      def insert_record(table, data={})
        obj = table.classify.constantize.new(data)
        yield obj
        obj.save!
      end

      # update a record
      def update_record(table, id, newdata = {})
        obj = table.classify.constantize.find(id)
        newdata.each do |k,v|
          obj[k] = v
        end
        yield obj
        obj.save!
     end

      # delete a record without ActiveRecord callbacks
      def delete_record(table, id)
        obj = table.classify.constantize.delete(id)
      end

      # delete a record with ActiveRecord callbacks
      def destroy_record(table, id)
        obj = table.classify.constantize.destroy(id)
      end
    end
  end
end

