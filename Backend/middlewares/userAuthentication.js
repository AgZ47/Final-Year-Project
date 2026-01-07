async function userAuthentication(req, res, next) {
  const token = req.headers.token;

  const uid = await jwt.verify(token, process.env.JWT_KEY);

  if (uid) {
    req.uid = uid;
    next();
  } else {
    return res.status(403).json({
      message: "failed to authenticate user",
    });
  }
}

module.exports = {
  userAuthentication,
};
