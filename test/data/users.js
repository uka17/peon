module.exports.usersOK = {
  mickey: {
    email: "mickey@example.com",
    password: "superSecret118*"
  },
  tom: {
    email: "tom@example.com",
    password: "MyPassword11+"
  }  
};
module.exports.usersNOK = {
  alice: {
    email: "alice@example.com"
  },
  bob: {
    login: "bob@example.com",
    password: "Ihatealice99-"
  }  
};
module.exports.usersBadPassword = {
  monika: {
    email: "monika@example.com",
    password: "123"
  },
  linda: {
    login: "linda@example.com",
    password: "password"
  }  
}