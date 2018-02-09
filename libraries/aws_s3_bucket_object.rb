require '_aws'

class AwsS3BucketObject < Inspec.resource(1)
  name 'aws_s3_bucket_object'
  desc 'Verifies settings for a s3 bucket objects'
  example "
    describe aws_s3_bucket_object(bucket_name: 'test_bucket', object_key 'test_object') do
      it { should exist }
    end
  "

  include AwsResourceMixin
  attr_reader :bucket_name, :object_key, :region

  def to_s
    "S3 Bucket Object #{@bucket_name}/#{@object_key}"
  end

  def object_acl
    # This is simple enough to inline it.
    @object_acl ||= fetch_object_acl
  end

  def bucket_policy
    @bucket_policy ||= fetch_bucket_policy
  end

  def public?
    # first line just for formatting
    false || \
      object_acl.any? { |g| g.grantee.type == 'Group' && g.grantee.uri =~ /AllUsers/ } || \
      object_acl.any? { |g| g.grantee.type == 'Group' && g.grantee.uri =~ /AuthenticatedUsers/ } || \
      bucket_policy.any? { |s| s.effect == 'Allow' && s.principal == '*' }
  end

  private

  def validate_params(raw_params)
    validated_params = check_resource_param_names(
      raw_params: raw_params,
      allowed_params: [:bucket_name, :object_key],
    )

    if validated_params.empty? or !validated_params.key?(:bucket_name) or !validated_params.key?(:object_key)
      raise ArgumentError, 'You must provide a bucket_name and object_key to aws_s3_bucket_object.'
    end

    validated_params
  end

  def fetch_from_aws
    backend = AwsS3BucketObject::BackendFactory.create

    # Since there is no basic "get_bucket" API call, use the
    # region fetch as the existence check.
    begin
      @region = backend.get_bucket_location(bucket: bucket_name).location_constraint
    rescue Aws::S3::Errors::NoSuchBucket
      @exists = false
      return
    end
    # TODO: actually lookup object
    @exists = true
  end

  def fetch_object_acl
    backend = AwsS3BucketObject::BackendFactory.create

    begin
      return backend.get_object_acl(bucket: bucket_name, key: object_key).grants
    rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::NoSuchBucket
      return []
    end
  end

  def fetch_bucket_policy
    backend = AwsS3BucketObject::BackendFactory.create

    begin
      # AWS SDK returns a StringIO, we have to read()
      raw_policy = backend.get_bucket_policy(bucket: bucket_name).policy
      return JSON.parse(raw_policy.read)['Statement'].map do |statement|
        lowercase_hash = {}
        statement.each_key { |k| lowercase_hash[k.downcase] = statement[k] }
        OpenStruct.new(lowercase_hash)
      end
    rescue Aws::S3::Errors::NoSuchBucketPolicy, Aws::S3::Errors::NoSuchBucket
      return []
    end
  end

  # Uses the SDK API to really talk to AWS
  class Backend
    class AwsClientApi
      BackendFactory.set_default_backend(self)

      def get_object_acl(query)
        AWSConnection.new.s3_client.get_bucket_acl(query)
      end

      def get_bucket_location(query)
        AWSConnection.new.s3_client.get_bucket_location(query)
      end

      def get_bucket_policy(query)
        AWSConnection.new.s3_client.get_bucket_policy(query)
      end
    end
  end
end
