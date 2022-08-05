pragma solidity >=0.7.0 <0.9.0;
import './RealMath.sol';

library Geo {
  function getDistance(int128 lat1, int128 lon1, int128 lat2, int128 lon2 ) private pure returns(int128) {
    int128 R = 6371; // Radius of the earth in km
    int128  dLat = deg2rad(lat2-lat1);  // deg2rad below
    int128  dLon = deg2rad(lon2-lon1); 
    int128  a = 
      RealMath.sin(dLat/2) * RealMath.sin(dLat/2) +
      RealMath.cos(deg2rad(lat1)) * RealMath.cos(deg2rad(lat2)) * 
      RealMath.sin(dLon/2) * RealMath.sin(dLon/2)
    ; 
    int128  c = 2 * RealMath.atan2(RealMath.sqrt(a), RealMath.sqrt(1-a)); 
    int128 d = R * c; // Distance in km
    return d;
  }

  function deg2rad(int128 deg) private pure returns (int128){
    return deg * (RealMath.REAL_PI/180);
  }
}