function Im= loadImage(self)

Args=self.Set;
Im = AstroImage(self.ImagePath,'CCDSEC',[Args.CCDSEC_xd,Args.CCDSEC_xu,Args.CCDSEC_yd,Args.CCDSEC_yu]   );
Im.Image = single(Im.Image);

end