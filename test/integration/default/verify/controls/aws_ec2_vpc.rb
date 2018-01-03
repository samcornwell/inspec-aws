control "aws_ec2_vpc" do
  describe aws_ec2_vpc do
    it { should exist}
  end
end
