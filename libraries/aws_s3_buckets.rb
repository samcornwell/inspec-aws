class AwsS3Buckets < Inspec.resource(1)
  name 'aws_s3_buckets'
  desc 'Verifies settings for AWS S3 Buckets in bulk'
  example '
    describe aws_s3_buckets do
      it { should exist }
    end
  '

  # Constructor.  Args are reserved for row fetch filtering.
  def initialize(raw_criteria = {})
    #validated_criteria = validate_filter_criteria(raw_criteria)
    fetch_from_backend(raw_criteria)
  end

  # Underlying FilterTable implementation.
  filter = FilterTable.create
  filter.add_accessor(:where)
        .add_accessor(:entries)
        .add(:exists?) { |x| !x.entries.empty? }
  filter.connect(self, :access_key_data)

  def access_key_data
    @table
  end

  def to_s
    'S3 Buckets'
  end

  private
=begin
  def validate_filter_criteria(raw_criteria)
    unless raw_criteria.is_a? Hash
      raise 'Unrecognized criteria for fetching S3 Buckets. ' \
            "Use 'criteria: value' format."
    end

    # No criteria yet
    recognized_criteria = check_criteria_names(raw_criteria)

    recognized_criteria
  end

  def check_criteria_names(raw_criteria: {}, allowed_criteria: [])
    # Remove all expected criteria from the raw criteria hash
    recognized_criteria = {}
    allowed_criteria.each do |expected_criterion|
      recognized_criteria[expected_criterion] = raw_criteria.delete(expected_criterion) if raw_criteria.key?(expected_criterion)
    end

    # Any leftovers are unwelcome
    unless raw_criteria.empty?
      raise ArgumentError, "Unrecognized filter criterion '#{raw_criteria.keys.first}'. Expected criteria: #{allowed_criteria.join(', ')}"
    end
    recognized_criteria
  end
=end
  def fetch_from_backend(criteria)
    @table = []
    backend = AwsS3Buckets::BackendFactory.create
    # Note: should we ever implement server-side filtering
    # (and this is a very good resource for that),
    # we will need to reformat the criteria we are sending to AWS.
    results = backend.list_buckets(criteria)
    results.buckets.each do |b_info|
      @table.push({
        name: b_info.name,
        creation_date: b_info.creation_date,
        owner: {
          display_name: results.owner.display_name,
          id: results.owner.id
        },
      })
    end
  end

  class BackendFactory
    extend AwsBackendFactoryMixin
  end

  class Backend
    class AwsClientApi < Backend
      AwsS3Buckets::BackendFactory.set_default_backend self

      def list_buckets(query)
        AWSConnection.new.s3_client.list_buckets(query)
      end
    end
  end
end
