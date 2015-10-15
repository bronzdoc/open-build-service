# BackendFile model to represent files that belongs to the package in the backend
class PackageFile < BackendFile

  attr_accessor :project_name, :package_name

  validates :project_name, :package_name, presence: true

  # calculates the real url on the backend to search the file
  def full_path(params = {})
    query = params.blank? ? '' : "?#{params.to_query}"
    URI.encode("/source/#{project_name}/#{package_name}/#{name}") + query
  end

end
