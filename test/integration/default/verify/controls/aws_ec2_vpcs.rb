fixtures = {}
[
  'ec2_security_group_default_vpc_id',
].each do |fixture_name|
  fixtures[fixture_name] = attribute(
    fixture_name,
    default: "default.#{fixture_name}",
    description: 'See ../build/ec2.tf',
  )
end

control 'aws_ec2_vpcs' do
  describe aws_ec2_vpcs do
    its('entries.length') { should be 1 }
    its('entries.first.vpc_id') { should eq fixtures['ec2_security_group_default_vpc_id'] }
  end
end
