function cost = elastic_joint_cost(angles,eq_angles,joint_elast)
%Cost to find limb configuration in elastic joint condition

cost = sum(joint_elast.*(angles(:)-eq_angles(:)).^2);