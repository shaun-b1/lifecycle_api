module Api
  module V1
    class ResponseService
      class << self
        def success(data = nil, message = nil, meta = {})
        {
          json: {
            success: true,
            message: message,
            data: data,
            meta: meta
          }.compact,
          status: :ok
        }
        end

        def empty_success(status = :no_content)
          {
            json: {
              success: true
            },
            status: status
          }
        end

        def created(data = nil, message = "Resource created successfully", meta = {})
          {
            json: {
              success: true,
              message: message,
              data: data,
              meta: meta
            }.compact,
            status: :created
          }
        end

        def updated(data = nil, message = "Resource updated successfully", meta = {})
          {
            json: {
              success: true,
              message: message,
              data: data,
              meta: meta
            }.compact,
            status: :ok
          }
        end

        def deleted(message = "Resource deleted successfully")
          {
            json: {
              success: true,
              message: message
            },
            status: :ok
          }
        end

        def paginated(collection, meta = {})
        {
          json: {
            success: true,
            data: [],
            meta: meta.merge(
              pagination: {
                current_page: collection.current_page,
                total_pages: collection.total_pages,
                total_count: collection.total_count,
                per_page: collection.limit_value
              }
            )
          }.compact,
          status: :ok
        }
      end
      end
    end
  end
end
