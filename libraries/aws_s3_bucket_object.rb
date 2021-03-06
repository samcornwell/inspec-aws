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

  def path
    "#{@bucket_name}/#{@object_key}"
  end

  def to_s
    "S3 Bucket Object #{@bucket_name}/#{@object_key}"
  end

  def object_acl
    @object_acl ||= fetch_object_acl
  end

  def object_owner
    @object_owner ||= fetch_object_owner
  end

  def bucket_policy
    @bucket_policy ||= fetch_bucket_policy
  end

  def has_acl_public_read?
    false || \
      object_acl.select { |g| g.grantee.type == 'Group' && g.grantee.uri =~ /AllUsers/ }.map(&:permission).include?('READ') || \
      object_acl.select { |g| g.grantee.type == 'Group' && g.grantee.uri =~ /AuthenticatedUsers/ }.map(&:permission).include?('READ')
  end

  def has_acl_public_write?
    false || \
      object_acl.select { |g| g.grantee.type == 'Group' && g.grantee.uri =~ /AllUsers/ }.map(&:permission).include?('WRITE') || \
      object_acl.select { |g| g.grantee.type == 'Group' && g.grantee.uri =~ /AuthenticatedUsers/ }.map(&:permission).include?('WRITE')
  end

  def has_acl_owner_full_control?
    false || \
      object_acl.select { |g| g.grantee.type == 'CanonicalUser' && g.grantee.id == object_owner.id }.map(&:permission).include?('FULL_CONTROL')
  end

  def public?
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
      backend.get_object(bucket: bucket_name, key: object_key)
    rescue Aws::S3::Errors::NoSuchBucket, Aws::S3::Errors::NoSuchKey
      @exists = false
      return
    end
    @exists = true
  end

  def fetch_object_acl
    return [] unless @exists

    backend = AwsS3BucketObject::BackendFactory.create

    backend.get_object_acl(bucket: bucket_name, key: object_key).grants
  end

  def fetch_object_owner
    return {} unless @exists

    backend = AwsS3BucketObject::BackendFactory.create

    backend.get_object_acl(bucket: bucket_name, key: object_key).owner
  end

  def fetch_bucket_policy
    return [] unless @exists

    backend = AwsS3BucketObject::BackendFactory.create

    begin
      # AWS SDK returns a StringIO, we have to read()
      raw_policy = backend.get_bucket_policy(bucket: bucket_name).policy
      return JSON.parse(raw_policy.read)['Statement'].map do |statement|
        lowercase_hash = {}
        statement.each_key { |k| lowercase_hash[k.downcase] = statement[k] }
        OpenStruct.new(lowercase_hash)
      end
    rescue Aws::S3::Errors::NoSuchBucketPolicy, Aws::S3::Errors::NotImplemented
      return []
    end
  end

  # Uses the SDK API to really talk to AWS
  class Backend
    class AwsClientApi
      BackendFactory.set_default_backend(self)

      def get_object_acl(query)
        AWSConnection.new.s3_client.get_object_acl(query)
      end

      def get_bucket_location(query)
        AWSConnection.new.s3_client.get_bucket_location(query)
      end

      def get_bucket_policy(query)
        AWSConnection.new.s3_client.get_bucket_policy(query)
      end

      def get_object(query)
        AWSConnection.new.s3_client.get_object(query)
      end
    end
  end
end
