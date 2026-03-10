/** Landing page data — pure functions, no React */

export interface AgentCard {
  id: number;
  imageUrl: string;
}

export interface CityInfo {
  name: string;
  state: string;
  label: string;
}

export interface TrustChip {
  label: string;
}

/** Static agent card images for the hero background grid */
export function getAgentCards(): AgentCard[] {
  return [
    { id: 1, imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuBO7ZbXay4G9ftQpp74C5HoOZ3eHbaKDKTjCkzsifvs3X1N09BoVssqFuT9TNeVJIVk7XzA0oGdgdZv3rv5dSbO5JIrrw9RPzZYCgtG60RWkDn_wL9FLqRbR9Q3vbFj-iXAmYxmv9CHPeZfoDWTSw5dBvEperZ3QK88kf0LBTpimbXa9j_ymV00c6g5r007ntqnZ1z0tp4hqCpmqjtRGp8f00CBsu_Q6CqqLK3WhzJY7QyiNt7bNeO2d9rBXOmoSALM5R7_W6_VEAE" },
    { id: 2, imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuD4uYe8xY2lqU9-IarNVaFbd5sTOX6_5lyBLk6wt9vcDEKkHWRQhKjISYsuMZrZkCXhv__NYtnc_ekZa8wcH42u0F5gyjwqMkEa4W4JUgF6MhovXKBsRN8rONefwofQuPWa8AmC2Z1xz-wEFMODIzI2ILZbMOH1rYhh4xVXE3q77I_8_Bdmkys-RM0yeOTknMkPZ8QAa7Nwi_6gCtXgL_z13hiA6uIvGMtYDjAPjVz-UK6ehkjpw42-sqGBjcG-ptMJoTpk2c46ptI" },
    { id: 3, imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuCqpQYhBI0xJzFlm6MmZNoTauehyKtC7knWjs6zopszKmhLmDCcah8Tfr9CSYG7IVTKspVztOaO92EzP2Jp0NlkXbecOPNQZ6JQlDdFP16YqQxa241GIlYVrrwICaOo4vyDD2r90MWCzqQ3a4M247Xr63WO-8zhS3NwU8ZuNALIBcJK1azkqG-HFUGPCUFJGoDGjitwO_zBJkLrz_UXGhGQJSJqUtI6kTqNH-tva-LieHkFoCw1S4wX95S_r4UTpRCUbx_0uALNPnQ" },
    { id: 4, imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuCOiO7HXRGIrJwZA0sI3GzGs48WmbOh9N-ftuDY54zgJR2qfFMpGiLYWoLfrZCkvBxrZgfzml_Ee7DxjUUAegwclyThgoicMIBjS-j-3t2ObnqKuuXDXI9-l8r3MjC3eP-35F4RjW5axAQlF2Ze2IneEef2GrjJe4V--BSeDeYDtreykoE6BAndPsGTGVxJFl9ciinXVtH3OYx2_HCgPf3dnrc_VJqOu3g_FK9OVIhf_JbiegT84ITa2fqDdJ2PFDz4pWdusnPxBPI" },
    { id: 5, imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuAS5XQ5r-sy_040UWWDvhpZJivi7p-Xh5HNR9QNWEgm8pbQ09vNdMqTIiSXmpgrf6Z2i3t9yH1oAN1BGvrthoYk_LUFDA6fSMvS44hWJliyFhIYtNeSbgGBSlUM1Gvkt5SDTXq3_Y3o-9xJEphT9m1QT1Vqk982qvJso8UtK7eJX6_FN1uPBZWCXXis2BUihaiEAlkqWr-TTOsRIGVNa1srIAui7vmOaW1do_3nt_ADcslQBHBiBWUBCu7n8O5nXPzlN9tnXO3_Md0" },
    { id: 6, imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuATU5k-MUbXVUiOqf7hlc7JMc4imI0s1I5eI-unQAouJ3TrB7dPAQoFy2e6IC_fbPia2qImgj_oaLXClEUxCAkKJn4zsc2KJ6Bgaw8U9zUpA-nzM3kVRDQ0oMPd9axyTUeOD7CvbrAbaTYc_15lWHbaGR3rJvlneQh2lFMOXBMVLlMIJgbchsQuwISQcZo38XmRnBqTZlOohOwhXVnY9RdpiDLGcf1WE6a_X3ysN3wdqEnTh9VfJfF8k9FNMCSXas9IuAdGhdEGCCo" },
    { id: 7, imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuCVm6FB50G3pp1eqXdiHZTNzUAuhWDMMlPKW-wmvkpP1WC8KzpbViYebj0sRMTn8GMg1UmsYNU3Ofij_2QTDT1ANNLshfm1t8Pc5tg8ttQXez-fay_4ra1OAbEjcM3wxCjcJTqtdVh7w0naJRp_7ZaH7HNs5ldm5QW0qIGhg2HiR29yFUInanLHZrjFA0V6jyoJ06bjDq8WDO3bQ4NltDA7gQv_eJRmK_64Z7LfozNaLagTRBME6yDPR5metD82qsY20CSI-ND3W-U" },
    { id: 8, imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuC2yRk8uD4-FzZfjtd_26X42RO4udZ-s5daccoEdCJxgWvSVlw9d0hch_G8TJvyoGN2bNg0mEwlgtcbOiBf8m34ieTVkhzF_kFkuPZDxEk5N4ePdP-GqvNPzz_Hz3lPc5dH6mad9100ESt8wghktqXxsCPSEUCSBabWMwi1dxBG20iYDdI61Sz1O28zzheIJIaVpRbeT771-JjmIT8VEizpgIfnC0R1Fcx89zZYDZyGhsoi2FM-94fisCDwwSmcMO1-5-yJdLNBVz0" },
    { id: 9, imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuCCsKMsEZbUyQgj8UVhcoH42UC4TWiv6mZ5eYS6iGPXCoGDesQg7F5E73RHaJ6BeqnKazB6EpxK-9RC0IRXyFJ6dN2OGH59tlzz_p5GlaVWhezOsnfblDa1j617UD0Ta3_mTCjAlgahz-1dTD37-Fau5QtChbFWNpoxmEMGNWanNU6x4dfL0CeiDEka45bm1rkjOxk_tsoSYkxqQdzAthU9xGHYuH7SeWqm16ibYHCgLcEC37mwdUHMfwj5q59XXQlYC5bpjXXBNi0" },
    { id: 10, imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuAuWV_pdkA6whl0uHgOMJwy-8ibfmBBIZSQBTMiDbCLjdUS4fhtc5dGGej67ZqHqbsaV5k9r8csjAfrmpLMz56Kcb0Cxl1Lk2oCUvVq-X3-FPOf3paHALdOfc9u6S5IK93gTpL33Y5_ryXQUESpTVCaaDVfvzbI_apKJtXw6AU4Gw_j5SUj0HpTYcidrEPvOr88wQbrCaLiSwk_Oqj317mK4u42A7gZ-vj3xiZHdICTu_ILCDL7JAPn2kv_438sqIZkTY1k3pjB-1c" },
    { id: 11, imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuCqEHO4GaNDcI-W2qMpppAswyaAjM5p19Ru58bICXb0mvlwDVVzZqcRt8c_VLfe7_cZpiRjMrQBHh0RwfyAqlothZ7kPp3_RM0EGYFjyfjFxD7anACbVtO5t2KiAG8oJbWtM9UGQlaINxRRwo8qqtKH36q29Zqc95g6YkAZU0jjR0iCmnab2hmtZF7sl-f0IwkZOzd862_1X6V-Bl5BTssLsSfSSdAwCrVZ0E_O87sHf885-IM18ZmOIpp7zzgbCUmzh50fyt1XfHQ" },
    { id: 12, imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuBY_--fhDeCciNFHPIFDovRoe8pWDY3J1MzCTJx3Z1GpWSAIhYeRJ7h-jpBWgS3pUDiliXXnsa4edsnxvcvOK4BEONKfn9zY15HhhTCG4C46zXDxa29McylhCPO5EPlG32fgOZCdXc3b8Pe1TkXIt1ki28i54N2P6fJD9tQXDuv3XOoId5yn_JQ1HPxvy3jRpOn0_slB1Mh2AP0i_Q05-XBqZLPe6IS_TfvOh-56dIMoIcRfTZeuN7UPR2b0lyNqDEba3zmypsbtTo" },
    { id: 13, imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuDOOMG573F7F85tXXTE_tOsmxJhXfFH5vO0LiQB0qjZ6ItWWailfTZ6Jgo71LceqsXspdeQFZcJxST3HG0RS6VAsyr-UHq0sdzbPu66JiHuSOOrzIwqT30mPhB5t01y87Ti3UkELaKxu7dA0WOPdafcIjJ538Bzk3LmEAfM0oaL24hsJZVq3KtBnquoDflOeVvurkWM8Gmu9oxlLuMklliEqKdzo0CEtCPLsrOjXt0WNiKYu_DY-hhw0tmLePQNxPVrWYTYkpU8hCU" },
    { id: 14, imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuDU2DkEVs6tsXPcOBs-wvl6WEd1Xn2sLJzIm7s6hUkRQ7b-oRiXJsFiXHztmpY0TgR_jVAW-NUVhxoLEkSFmBHUAGH5mEgo3dUkYy2Nr9nxxMZhf_QivHHIPcVUdOZMKwKbrdv7GdimYr5j3M58BLs1YRif7XnYLE4PY2XnPOvEDUEtnDZ6tuGNTXoLPUj_e0Cs1KSSQU4hzhG-bXp2chZRcEPIK1FVQJOxw52boqEY3Uo0pxLLuyDkL1U_ml3S0XCfcOQwW8UugZI" },
    { id: 15, imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuCg1RBAzn4BCz6ejF_r2YpJfVfdWsKYOIn_AIQ-q134in5C08Nvbzf6iW2lsiLgTjswaPMLST4FZ5YLnVSFifqaSQXEXsYwwukcLhoNlDiJvCH2Nk2iBLU-_MKmGaJORQhKa4oUXaPn-6ifJA-oKSYQA7EANE0kanuWuNULWJKuxbdVWSXbfR0thVwTQMcU73OsxeXQD5M0zNxHnkCES_9agWybGQfdLRloPeM6W3T51D-23B-sdsCfh4BNA_BfnokGljRL-cM3mYs" },
  ];
}

/** Get current city info */
export function getCityInfo(): CityInfo {
  return {
    name: "Kirkland",
    state: "WA",
    label: "Kirkland, WA",
  };
}

/** Get trust chips */
export function getTrustChips(): TrustChip[] {
  return [
    { label: "Verified businesses" },
    { label: "Local to Kirkland" },
    { label: "Secure messaging" },
    { label: "Response-aware" },
  ];
}

/** Hero content */
export function getHeroContent() {
  return {
    eyebrow: "Licensed advisors. Fast discovery.",
    headline: "Find the right advisor in minutes.",
    subheadline:
      "Browse verified Kirkland-area financial and insurance professionals matched to your goals, communication style, and location.",
    ctaLabel: "Continue with work email",
    secondaryCta: "Log in",
  };
}
