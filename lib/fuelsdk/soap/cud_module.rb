module FuelSDK
  module Soap
    module CUD #create, update, delete
    puts "Soap::CUD was loaded!"

      def post
        if self.respond_to?('folder_property') && !self.folder_id.nil?
          properties[self.folder_property]  = self.folder_id
        elsif self.respond_to?('folder_property') && !self.folder_property.nil? && !client.package_name.nil? then
          if client.package_folders.nil? then
            getPackageFolder = FuelSDK::Folder.new(client)
            getPackageFolder.properties = ["ID", "ContentType"]
            getPackageFolder.filter = {"Property" => "Name", "SimpleOperator" => "equals", "Value" => client.package_name}
            resultPackageFolder = getPackageFolder.get
            if resultPackageFolder.status then
              client.package_folders = {}
              resultPackageFolder.results.each do |value|
                client.package_folders[value[:content_type]] = value[:id]
              end
            else
              raise "Unable to retrieve folders from account due to: #{resultPackageFolder.message}"
            end
          end

          if !client.package_folders.has_key?(self.folder_media_type) then
            if client.parentFolders.nil? then
              parentFolders = FuelSDK::Folder.new(client)
              parentFolders.properties = ["ID", "ContentType"]
              parentFolders.filter = {"Property" => "ParentFolder.ID", "SimpleOperator" => "equals", "Value" => "0"}
              resultParentFolders = parentFolders.get
              if resultParentFolders.status then
                client.parent_folders = {}
                resultParentFolders.results.each do |value|
                  client.parent_folders[value[:content_type]] = value[:id]
                end
              else
                raise "Unable to retrieve folders from account due to: #{resultParentFolders.message}"
              end
            end

            newFolder = FuelSDK::Folder.new(client)
            newFolder.properties = {"Name" => client.package_name, "Description" => client.package_name, "ContentType"=> self.folder_media_type, "IsEditable"=>"true", "ParentFolder" => {"ID" => client.parentFolders[self.folder_media_type]}}
            folderResult = newFolder.post
            if folderResult.status then
              client.package_folders[self.folder_media_type]  = folderResult.results[0][:new_id]
            else
              raise "Unable to create folder for Post due to: #{folderResult.message}"
            end

          end
          properties[self.folder_property] = client.package_folders[self.folder_media_type]
        end
        client.soap_post id, properties
      end

      def patch
        client.soap_patch id, properties
      end

      def delete
        client.soap_delete id, properties
      end
    end
  end
end
