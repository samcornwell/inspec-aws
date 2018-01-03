class AwsEc2Vpcs < Inspec.resource(1)
  name 'aws_ec2_vpcs'
  desc 'Verifies settings for AWS EC2 VPCS in bulk'
  example '
    describe aws_ec2_vpcs do
      it { should exist }
    end
  '
  include AwsResourceMixin

  def validate_params(raw_params)
    validated_params = check_resource_param_names(
      raw_params: raw_params,
      allowed_params: [],
    )
    validated_params
  end

  # Underlying FilterTable implementation.
  filter = FilterTable.create
  filter.add_accessor(:where)
        .add_accessor(:entries)
        .add(:exists?) { |x| !x.entries.empty? }
        .add(:vpc_id, field: :vpc_id)
  filter.connect(self, :access_key_data)

  def access_key_data
    @table
  end

  def to_s
    'EC2 VPCs'
  end

  private

  def fetch_from_aws
    @table = []
    backend = AwsEc2Vpcs::BackendFactory.create
    # Note: should we ever implement server-side filtering
    # (and this is a very good resource for that),
    # we will need to reformat the criteria we are sending to AWS.
    results = backend.describe_vpcs()
    results.vpcs.each do |vpc_info|
      @table.push(vpc_info.to_h)
    end
  end

  class BackendFactory
    extend AwsBackendFactoryMixin
  end

  class Backend
    class AwsClientApi < Backend
      AwsEc2Vpcs::BackendFactory.set_default_backend self

      def describe_vpcs(query = {})
        AWSConnection.new.ec2_client.describe_vpcs(query)
      end
    end
  end
end
