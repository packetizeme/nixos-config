self: super: {
  uhd = super.uhd.override {
    enableUtils = true;
    enableExamples = true;
  };

}
