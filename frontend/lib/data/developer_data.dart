
import 'package:movie_booking_app/data/models/developer_model.dart';

class DeveloperData {
  static List<DeveloperModel> teamMembers = [
    DeveloperModel(
      id: 1,
      name: "Song Kimvisal",
      role: "Project Lead & Frontend Developer",
      imageUrl: "assets/developer_pf/kimvisal.jpg",
      description:
          "Led the development of this movie booking application, responsible for architecture design and full-stack implementation.",
      email: "song.kimvisal@movieapp.com",
      github: "github.com/songkimvisal",
    ),
    DeveloperModel(
      id: 2,
      name: "Leak Sithisak",
      role: "Backend Developer",
      imageUrl: "assets/developer_pf/sithisak.jpg",
      description:
          "Specialized in Flutter development, focusing on creating smooth user interfaces and implementing seat selection functionality.",
      email: "leak.sithisak@movieapp.com",
      github: "github.com/leaksithisak",
    ),
    DeveloperModel(
      id: 3,
      name: "Sim Kimchhun",
      role: "Database Design / Analyst",
      imageUrl: "assets/developer_pf/kimchhun.jpg",
      description:
          "Built the robust backend API handling movie data, user authentication, and booking management systems.",
      email: "sim.kimchhun@movieapp.com",
      github: "github.com/simkimchhun",
    ),
  ];
}
