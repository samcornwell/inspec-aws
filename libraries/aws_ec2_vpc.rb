class AwsEc2Vpc < Inspec.resource(1)
  name 'aws_ec2_vpc'
  desc 'Verifies settings for AWS EC2 VPC'
  example '
    describe aws_ec2_vpc do
      it { should exist }
    end
  '
  include AwsResourceMixin

  def validate_params(raw_params)
    validated_params = check_resource_param_names(
      raw_params: raw_params,
      allowed_params: [:vpc_id],
      allowed_scalar_name: :vpc_id,
      allowed_scalar_type: String
    )
    validated_params
  end

  def to_s
    'EC2 VPC'
  end

  private

  def fetch_from_aws
    backend = AwsEc2Vpc::BackendFactory.create

    if @vpc_id.nil?
      filter = { name: "isDefault", values:["true"] }
    else
      filter = { name: "vpc-id", values:[@vpc_id] }
    end

    resp = backend.describe_vpcs({filters: [filter]})

    @vpc = resp.vpcs[0].to_h
    @vpc_id = @vpc[:vpc_id]
    @exists = !@vpc.empty?
  end

  class BackendFactory
    extend AwsBackendFactoryMixin
  end

  class Backend
    class AwsClientApi < Backend
      AwsEc2Vpc::BackendFactory.set_default_backend self

      def describe_vpcs(query = {})
        AWSConnection.new.ec2_client.describe_vpcs(query)
      end
    end
  end
end
